<%@ page import="java.sql.*" %>
<%@ page import="java.net.HttpURLConnection" %>
<%@ page import="java.net.URL" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.io.InputStreamReader" %>
<%@ page import="org.json.JSONObject" %>
<%@ page import="org.json.JSONArray" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.HashMap" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="WEB-INF/db_config.jsp" %>


<%
    String username = (String) session.getAttribute("username");
    Integer userID = (Integer) session.getAttribute("userID");

    if (username == null) 
    {
        response.sendRedirect("login.jsp");
        return;
    }

    String tripIdParam = request.getParameter("tripId");
    if (tripIdParam == null) 
    {
        response.sendRedirect("view_trips.jsp");
        return;
    }
    int tripId = Integer.parseInt(tripIdParam);

    //get trip info
    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    String tripStartLocation = "";
    String tripDestination = "";
    String tripStartDate = "";
    String tripEndDate = "";

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS); 
        pstmt = con.prepareStatement(
            "SELECT destination, start_date, end_date FROM Trip WHERE tripID = ? AND userID = ?"
        );
        pstmt.setInt(1, tripId);
        pstmt.setInt(2, userID);
        rs = pstmt.executeQuery();

        if (rs.next()) {
            tripDestination = rs.getString("destination");
            tripStartDate = rs.getString("start_date");
            tripEndDate = rs.getString("end_date");
        }
        rs.close();
        pstmt.close();
    } 
    catch (Exception e) 
    {
        e.printStackTrace();
    }
 // searching parameters
    String searchLoc = request.getParameter("location");
    String inDate = request.getParameter("check_in_date");
    String outDate = request.getParameter("check_out_date");
    String numAdults = request.getParameter("adult_guests"); 
    /*<!-- String numChild = request.getParameter("child_guests"); not required -->*/
    if (numAdults == null) 
    {
        numAdults = "1";
    }
    
    // no info null
    boolean searched = (searchLoc != null && inDate != null && outDate != null);

    // cache hashmap
    ArrayList<HashMap<String, String>> hotelResults = new ArrayList<>();
    boolean fromCache = false;
    String searchError = null; 

    // if searchable (i.e., info not null)
    if (searched) {
        try {
            if (con == null || con.isClosed()) 
            {
                Class.forName(DB_DRIVER);
                con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
            }

            // query to see if recent and ordered by cost (fix? bc things not ordered by cost)
            pstmt = con.prepareStatement(
                "SELECT * FROM Hotel_Listing " +
                "WHERE location = ?"  +
                "AND description = ? " +
                "AND rating = ?" +
                "AND listing_status = 'active' AND company_userID IS NULL " +
                "AND last_fetched > DATE_SUB(NOW(), INTERVAL 30 DAY) "+
                "ORDER BY price_per_night ASC"
            );
            pstmt.setString(1, searchLoc.trim().toUpperCase());
            pstmt.setString(2, inDate);
            pstmt.setString(3,outDate);
            rs = pstmt.executeQuery();

            // before first row (means we have a result we can use): https://docs.raima.com/rdm/14_2/ug/jdbc/ResultSet/Method/isBeforeFirst.htm#:~:text=isBeforeFirst()%20Description:%20Retrieves%20whether%20the%20cursor%20is,the%20first%20row%20in%20this%20ResultSet%20object.
            if (rs.isBeforeFirst()) {
                fromCache = true;
                while (rs.next()) 
                {
                    HashMap<String, String> hotel = new HashMap<>();
                    hotel.put("hotelID", String.valueOf(rs.getInt("hotelID")));
                    hotel.put("hotel_name", rs.getString("hotel_name"));
                    hotel.put("location", rs.getString("location"));
                    hotel.put("description",rs.getString("description"));
                    hotel.put("rating",rs.getString("rating"));
                    hotel.put("price_per_night",rs.getString("price_per_night"));
                    hotel.put("thumbnail_url", rs.getString("thumbnail_url"));
                    hotelResults.add(hotel);
                }
                rs.close();
                pstmt.close();
            } 
            // nothing previously saved,use api
            else 
            {
                rs.close();
                pstmt.close();


                // api url info per the webapge
                String apiUrl = "https://serpapi.com/search?engine=google_hotels" +
                    "&q=" + URLEncoder.encode(searchLoc.trim().toUpperCase(), "UTF-8") +
                    "&check_in_date=" + URLEncoder.encode(inDate, "UTF-8") +
                    "&check_out_date=" + URLEncoder.encode(outDate, "UTF-8") +
                    "&adults=" + URLEncoder.encode(numAdults, "UTF-8")+
                    "&currency=USD&hl=en&type=2" +
                    "&api_key=" + URLEncoder.encode(SERPAPI_KEY, "UTF-8");

                URL url = new URL(apiUrl);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("GET");
                conn.setRequestProperty("Accept", "application/json");

                int responseCode = conn.getResponseCode();
                BufferedReader br;
                if (responseCode == 200)  // good 
                {
                    br = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                } 
                else 
                {
                    br = new BufferedReader(new InputStreamReader(conn.getErrorStream()));
                }

                StringBuilder apiResponse = new StringBuilder();
                String line;
                while ((line = br.readLine()) != null) 
                {
                    apiResponse.append(line);
                }
                br.close();

                if (responseCode != 200) 
                {
                    searchError = "API error. Please check location and try again.";
                } 
                // parse w json (we added it to lib)
                else 
                {
                    JSONObject json = new JSONObject(apiResponse.toString());

                    JSONArray properties = new JSONArray();
                    if (json.has("properties")) 
                    {
                        properties = json.getJSONArray("properties");

                    }

                    if (properties.length() == 0) 
                    { searchError = "No hotels & lodging options avaiable for specified search.";} 
                    // found hotels
                    else 
                    {
                       // delete outdated /duplicates
                        pstmt = con.prepareStatement(
                            "DELETE FROM Hotel_Listing " +
                            "WHERE location = ? AND company_userID IS NULL"
                        );
                        pstmt.setString(1, searchLoc.trim().toUpperCase());
                        pstmt.executeUpdate();
                        pstmt.close();

                        int maxResults = Math.min(properties.length(), 20);
                        for (int i = 0; i < maxResults; i++) {
                            JSONObject hotelObj = properties.getJSONObject(i);
                            String hotel_name = hotelObj.has("name") ? hotelObj.getString("name") : "Unknown";
                            String description = hotelObj.has("description") ? hotelObj.getString("description") : "";
                            String thumbnail = "";
                            if (hotelObj.has("images")) {
                                JSONArray images = hotelObj.getJSONArray("images");
                                if (images.length() > 0) {
                                    JSONObject firstImg = images.getJSONObject(0);
                                    if (firstImg.has("thumbnail")) {
                                        thumbnail = firstImg.getString("thumbnail");
                                    }
                                }
                            }
                            double price = 0;
                            double rating = 0;
                            if (hotelObj.has("rate_per_night")) 
                        {
                            JSONObject rate = hotelObj.getJSONObject("rate_per_night");
                            if (rate.has("extracted_lowest")) {
                                Object extracted = rate.get("extracted_lowest");
                                if (extracted instanceof Number) {
                                    price = ((Number) extracted).doubleValue();
                                } else if (extracted instanceof String) {
                                    try { price = Double.parseDouble((String) extracted); } catch (Exception e) {}
                                }
                            }
                        }
                            if (hotelObj.has("overall_rating")){
                                rating = hotelObj.getDouble("overall_rating");
                            }

                            pstmt = con.prepareStatement(
                                "INSERT INTO Hotel_Listing (hotel_name, location, description, rating, price_per_night, availability, listing_status,last_fetched,thumbnail_url) " +
                                "VALUES (?, ?, ?, ?, ?, 'available', 'active',NOW(), ?)",
                                Statement.RETURN_GENERATED_KEYS
                            );
                            pstmt.setString(1, hotel_name);
                            pstmt.setString(2, searchLoc.trim().toUpperCase());
                            pstmt.setString(3, description.length() > 500 ? description.substring(0, 500) : description);
                            pstmt.setDouble(4, rating);
                            pstmt.setDouble(5, price);
                            pstmt.setString(6,thumbnail);
                            pstmt.executeUpdate();

                            ResultSet keys = pstmt.getGeneratedKeys();
                            String newId = "0";
                            if (keys.next()) newId = String.valueOf(keys.getInt(1));
                            keys.close();
                            pstmt.close();

                            HashMap<String, String> hotel = new HashMap<>();
                            hotel.put("hotelID", newId);
                            hotel.put("hotel_name", hotel_name);
                            hotel.put("location", searchLoc.trim().toUpperCase());
                            hotel.put("description", description);
                            hotel.put("rating", String.valueOf(rating));
                            if(price > 0){
                                hotel.put("price_per_night", String.valueOf(price));
                            }
                            else{
                                continue; //if price 0, then just skip that hotel
                            }
                            hotel.put("thumbnail_url",thumbnail);
                            hotelResults.add(hotel);
                        }
                    }
                }
            }
        } 
        catch (Exception e) 
        {
            e.printStackTrace();
            searchError = "Error searching for hotels: " + e.getMessage();
        }
    }

    ArrayList<HashMap<String, String>> companyListings = new ArrayList<>();
    try {
        if (con == null || con.isClosed()) 
        {
            Class.forName(DB_DRIVER);
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        }
        pstmt = con.prepareStatement(
            "SELECT * FROM Hotel_Listing WHERE company_userID IS NOT NULL AND listing_status = 'active' AND last_fetched > DATE_SUB(NOW(), INTERVAL 30 DAY) ORDER BY price_per_night ASC "
        );
        rs = pstmt.executeQuery();
        while (rs.next()) {
            HashMap<String, String> listing = new HashMap<>();
            listing.put("hotelID", String.valueOf(rs.getInt("hotelID")));
            listing.put("hotel_name", rs.getString("hotel_name"));
            listing.put("location", rs.getString("location"));
            listing.put("description", rs.getString("description"));
            listing.put("rating", rs.getString("rating"));
            listing.put("price_per_night", rs.getString("price_per_night"));
            companyListings.add(listing);
        }
        rs.close();
        pstmt.close();
    } 
    catch (Exception e) 
    {
        e.printStackTrace();
    } 
    finally 
    {
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
    }
    %> 

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Travelog — Browse Hotels & Lodging</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div style="width: 100%; max-width: 820px; display: flex; justify-content: flex-end; gap: 12px; margin-bottom: -32px;">
        <a href="trip_details.jsp?tripId=<%= tripId %>" class="btn btn-secondary">Back to Trip</a>
    </div>

    <div class="hero">
        <div class="duck-mark hero" style="margin-bottom: -8px;"></div>
        <h1 class="brand-title">Hotels<span class="accent-dot">.</span></h1>
        <p class="brand-subtitle">Search hotels via Google Hotels.</p>
    </div>

    <div class="card card-wide" style="margin-bottom: 24px;">
        <h2>Search Hotels & Lodging</h2>
        <p style="color: var(--text-muted); font-weight: 500; font-size: 0.85rem; margin-top: 4px;">
            Fill the information below
        </p>

        <form action="browse_hotels.jsp" method="GET" style="margin-top: 18px;">
            <input type="hidden" name="tripId" value="<%= tripId %>">

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                <div class="form-group">
                    <label>Location</label>
                    <input type="text" name="location"
                           value="<%= searched ? searchLoc : "" %>"
                          placeholder="e.g. <%= "return".equals(searchLoc) ? "" : "City of your stay" %>" required>
                </div>
                
                <div class="form-group">
                <label>Number of Adult Guests</label>
                <input type="number" name="adult_guests" value="<%= searched ? numAdults : "1" %>" min="1" required > </input>
                </div>
                
            </div>

            <div style "display:grid; grid-template-comlumns: 1fr 1fr; gap: 12px;">
                <div class="form-group">
                    <label>Check in Date</label>
                    <input type="date" name="check_in_date"
                          value="<%= searched ? inDate : tripStartDate %>"
                           placeholder="MM-DD-YYYY" required>
                </div>
                <div class="form-group">
                <label>Check out Date</label>
                <input type="date" name="check_out_date"
                       value="<%= searched ? outDate : tripEndDate %>"
                       placeholder="MM-DD-YYYY" required>
                </div>
            </div>
            

            <button type="submit" class="btn btn-primary">Search Hotels</button>
        </form>
    </div>

    <% if (searchError != null) { %>
        <div class="card card-wide" style="margin-bottom: 24px;">
            <div class="alert alert-error"><%= searchError %></div>
        </div>
    <% } %>

    <% if (searched && hotelResults.size() > 0) { %>
        <div class="card card-wide" style="margin-bottom: 24px;">
            <h2>Hotels & Lodging Results
                <% if (fromCache) { %>
                    <span style="font-size: 0.7rem; color: var(--text-muted); font-family: 'DM Sans', sans-serif; font-weight: 500;">(cached — prices may have changed)</span>
                <% } %>
            </h2>
            <div class="trips-grid" style="margin-top: 16px;">
                <% for (HashMap<String, String> hotel : hotelResults) { %>
                    <div class="trip-card" style="flex-direction: row; align-items: center; gap: 16px;">
                        <div class="trip-icon planned" style="padding: 0; overflow: hidden; background: transparent; border: none;">
        <% if (hotel.get("thumbnail_url") != null && !hotel.get("thumbnail_url").isEmpty()) { %>
            <img src="<%= hotel.get("thumbnail_url") %>" style="width: 100%; height: 100%; object-fit: cover; border-radius: 50%;">
        <% } else { %>
            &#8962; <!-- Fallback to the house icon if no image is found -->
        <% } %>
    </div>

                        <div class="trip-details" style="flex: 1;">
                            <div class="trip-name"><%= hotel.get("hotel_name") %></div>
                            <div class="trip-route"><%= hotel.get("location") %> &rarr; <%= String.format("%.1f", Double.parseDouble(hotel.get("rating"))) %>&starf;</div>

                        </div>
                        
                        <div style="text-align: right;">
                            <div class="trip-name" style="color: var(--accent); font-size: 1.1rem;">$<%= String.format("%.2f", Double.parseDouble(hotel.get("price_per_night"))) %></div>
                            <form action="select_hotel.jsp" method="POST" style="margin-top: 8px;">
                                <input type="hidden" name="tripId" value="<%= tripId %>">
                                <input type="hidden" name="hotelID" value="<%= hotel.get("hotelID") %>">
                                 <input type="hidden" name="check_in_date" value="<%= inDate %>">
                                 <input type="hidden" name="check_out_date" value="<%= outDate%>">
                                <button type="submit" class="btn btn-primary" style="padding: 6px 16px; font-size: 0.8rem;">Select</button>
                            </form>
                        </div>
                    </div>
                <% } %>
            </div>
        </div>
    <% } %>
