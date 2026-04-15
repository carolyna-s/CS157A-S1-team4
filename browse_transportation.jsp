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
<%@ include file="/WEB-INF/db_config.jsp" %>

<%
    String username = (String) session.getAttribute("username");
    Integer userID = (Integer) session.getAttribute("userID");

    if (username == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String tripIdParam = request.getParameter("tripId");
    if (tripIdParam == null) {
        response.sendRedirect("view_trips.jsp");
        return;
    }
    int tripId = Integer.parseInt(tripIdParam);

    // Get trip info for prefilling
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
            "SELECT start_location, destination, start_date, end_date FROM Trip WHERE tripID = ? AND userID = ?"
        );
        pstmt.setInt(1, tripId);
        pstmt.setInt(2, userID);
        rs = pstmt.executeQuery();

        if (rs.next()) {
            tripStartLocation = rs.getString("start_location");
            tripDestination = rs.getString("destination");
            tripStartDate = rs.getString("start_date");
            tripEndDate = rs.getString("end_date");
        }
        rs.close();
        pstmt.close();
    } catch (Exception e) {
        e.printStackTrace();
    }

    // Search params
    String searchOrigin = request.getParameter("departure_id");
    String searchDest = request.getParameter("arrival_id");
    String searchDate = request.getParameter("outbound_date");
    String returnDate = request.getParameter("return_date");
    String searchDirection = request.getParameter("direction");
    if (searchDirection == null) searchDirection = "outbound";
    boolean searched = (searchOrigin != null && searchDest != null && searchDate != null);

    ArrayList<HashMap<String, String>> flightResults = new ArrayList<>();
    boolean fromCache = false;
    String searchError = null;

    if (searched) {
        try {
            // Check cache: results for this route/date from the last 30 days?
            if (con == null || con.isClosed()) {
                Class.forName(DB_DRIVER);
                con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
            }

            pstmt = con.prepareStatement(
                "SELECT * FROM Transport_Listing " +
                "WHERE departure_location = ? AND arrival_destination = ? " +
                "AND DATE(departure_time) = ? " +
                "AND last_fetched > DATE_SUB(NOW(), INTERVAL 30 DAY) " +
                "AND listing_status = 'active' AND company_userID IS NULL " +
                "ORDER BY base_cost ASC"
            );
            pstmt.setString(1, searchOrigin.trim().toUpperCase());
            pstmt.setString(2, searchDest.trim().toUpperCase());
            pstmt.setString(3, searchDate);
            rs = pstmt.executeQuery();

            if (rs.isBeforeFirst()) {
                // Cache hit
                fromCache = true;
                while (rs.next()) {
                    HashMap<String, String> flight = new HashMap<>();
                    flight.put("transportID", String.valueOf(rs.getInt("transportID")));
                    flight.put("transport_name", rs.getString("transport_name"));
                    flight.put("departure_location", rs.getString("departure_location"));
                    flight.put("arrival_destination", rs.getString("arrival_destination"));
                    flight.put("departure_time", rs.getString("departure_time"));
                    flight.put("arrival_time", rs.getString("arrival_time"));
                    flight.put("base_cost", rs.getString("base_cost"));
                    flightResults.add(flight);
                }
                rs.close();
                pstmt.close();
            } else {
                // Cache miss — call SerpAPI Google Flights
                rs.close();
                pstmt.close();

                String apiUrl = "https://serpapi.com/search.json?engine=google_flights" +
                    "&departure_id=" + URLEncoder.encode(searchOrigin.trim().toUpperCase(), "UTF-8") +
                    "&arrival_id=" + URLEncoder.encode(searchDest.trim().toUpperCase(), "UTF-8") +
                    "&outbound_date=" + URLEncoder.encode(searchDate, "UTF-8") +
                    "&currency=USD&hl=en&type=2" +
                    "&api_key=" + URLEncoder.encode(SERPAPI_KEY, "UTF-8");

                URL url = new URL(apiUrl);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("GET");
                conn.setRequestProperty("Accept", "application/json");

                int responseCode = conn.getResponseCode();
                BufferedReader br;
                if (responseCode == 200) {
                    br = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                } else {
                    br = new BufferedReader(new InputStreamReader(conn.getErrorStream()));
                }

                StringBuilder apiResponse = new StringBuilder();
                String line;
                while ((line = br.readLine()) != null) {
                    apiResponse.append(line);
                }
                br.close();

                if (responseCode != 200) {
                    searchError = "API error. Please check your airport codes and try again.";
                } else {
                    JSONObject json = new JSONObject(apiResponse.toString());

                    // Combine best_flights and other_flights
                    JSONArray allFlights = new JSONArray();
                    if (json.has("best_flights")) {
                        JSONArray best = json.getJSONArray("best_flights");
                        for (int i = 0; i < best.length(); i++) allFlights.put(best.getJSONObject(i));
                    }
                    if (json.has("other_flights")) {
                        JSONArray other = json.getJSONArray("other_flights");
                        for (int i = 0; i < other.length(); i++) allFlights.put(other.getJSONObject(i));
                    }

                    if (allFlights.length() == 0) {
                        searchError = "No flights found for this route and date.";
                    } else {
                        // Clear old cache for this route/date
                        pstmt = con.prepareStatement(
                            "DELETE FROM Transport_Listing " +
                            "WHERE departure_location = ? AND arrival_destination = ? " +
                            "AND DATE(departure_time) = ? AND company_userID IS NULL"
                        );
                        pstmt.setString(1, searchOrigin.trim().toUpperCase());
                        pstmt.setString(2, searchDest.trim().toUpperCase());
                        pstmt.setString(3, searchDate);
                        pstmt.executeUpdate();
                        pstmt.close();

                        int maxResults = Math.min(allFlights.length(), 20);
                        for (int i = 0; i < maxResults; i++) {
                            JSONObject flightObj = allFlights.getJSONObject(i);

                            // Get price
                            double price = 0;
                            if (flightObj.has("price")) {
                                price = flightObj.getDouble("price");
                            }

                            // Get first leg
                            JSONArray legs = flightObj.getJSONArray("flights");
                            JSONObject firstLeg = legs.getJSONObject(0);
                            JSONObject lastLeg = legs.getJSONObject(legs.length() - 1);

                            String airline = firstLeg.has("airline") ? firstLeg.getString("airline") : "Unknown";
                            String flightNo = firstLeg.has("flight_number") ? firstLeg.getString("flight_number") : "";
                            String depAirport = firstLeg.getJSONObject("departure_airport").getString("id");
                            String arrAirport = lastLeg.getJSONObject("arrival_airport").getString("id");

                            String depTime = firstLeg.getJSONObject("departure_airport").getString("time");
                            String arrTime = lastLeg.getJSONObject("arrival_airport").getString("time");

                            String displayName = airline;
                            if (!flightNo.isEmpty()) {
                                displayName += " " + flightNo;
                            }
                            if (legs.length() > 1) {
                                displayName += " (" + legs.length() + " stops)";
                            }

                            // Format for MySQL datetime
                            String depFormatted = depTime.replace("T", " ");
                            String arrFormatted = arrTime.replace("T", " ");
                            if (depFormatted.length() > 19) depFormatted = depFormatted.substring(0, 19);
                            if (arrFormatted.length() > 19) arrFormatted = arrFormatted.substring(0, 19);

                            // Insert into DB
                            pstmt = con.prepareStatement(
                                "INSERT INTO Transport_Listing (transport_type, transport_name, departure_location, " +
                                "arrival_destination, departure_time, arrival_time, base_cost, availability, listing_status, last_fetched) " +
                                "VALUES ('plane', ?, ?, ?, ?, ?, ?, 'available', 'active', NOW())",
                                Statement.RETURN_GENERATED_KEYS
                            );
                            pstmt.setString(1, displayName);
                            pstmt.setString(2, depAirport);
                            pstmt.setString(3, arrAirport);
                            pstmt.setString(4, depFormatted);
                            pstmt.setString(5, arrFormatted);
                            pstmt.setDouble(6, price);
                            pstmt.executeUpdate();

                            ResultSet keys = pstmt.getGeneratedKeys();
                            String newId = "0";
                            if (keys.next()) newId = String.valueOf(keys.getInt(1));
                            keys.close();
                            pstmt.close();

                            HashMap<String, String> flight = new HashMap<>();
                            flight.put("transportID", newId);
                            flight.put("transport_name", displayName);
                            flight.put("departure_location", depAirport);
                            flight.put("arrival_destination", arrAirport);
                            flight.put("departure_time", depFormatted);
                            flight.put("arrival_time", arrFormatted);
                            flight.put("base_cost", String.valueOf(price));
                            flightResults.add(flight);
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            searchError = "Error searching for flights: " + e.getMessage();
        }
    }

    // Get company-posted listings
    ArrayList<HashMap<String, String>> companyListings = new ArrayList<>();
    try {
        if (con == null || con.isClosed()) {
            Class.forName(DB_DRIVER);
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        }
        pstmt = con.prepareStatement(
            "SELECT * FROM Transport_Listing WHERE company_userID IS NOT NULL AND listing_status = 'active' ORDER BY base_cost ASC"
        );
        rs = pstmt.executeQuery();
        while (rs.next()) {
            HashMap<String, String> listing = new HashMap<>();
            listing.put("transportID", String.valueOf(rs.getInt("transportID")));
            listing.put("transport_name", rs.getString("transport_name"));
            listing.put("departure_location", rs.getString("departure_location"));
            listing.put("arrival_destination", rs.getString("arrival_destination"));
            listing.put("departure_time", rs.getString("departure_time"));
            listing.put("arrival_time", rs.getString("arrival_time"));
            listing.put("base_cost", rs.getString("base_cost"));
            companyListings.add(listing);
        }
        rs.close();
        pstmt.close();
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Travelog — Browse Transportation</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div style="width: 100%; max-width: 820px; display: flex; justify-content: flex-end; gap: 12px; margin-bottom: -32px;">
        <a href="trip_details.jsp?tripId=<%= tripId %>" class="btn btn-secondary">Back to Trip</a>
    </div>

    <div class="hero">
        <div class="duck-mark hero" style="margin-bottom: -8px;"></div>
        <h1 class="brand-title">Transportation<span class="accent-dot">.</span></h1>
        <p class="brand-subtitle">Search real-time flights via Google Flights.</p>
    </div>

    <div class="card card-wide" style="margin-bottom: 24px;">
        <h2>Search Flights</h2>
        <p style="color: var(--text-muted); font-weight: 500; font-size: 0.85rem; margin-top: 4px;">
            Use IATA airport codes (e.g. SJC, LAX, JFK, SFO, ORD)
        </p>

        <form action="browse_transportation.jsp" method="GET" style="margin-top: 18px;">
            <input type="hidden" name="tripId" value="<%= tripId %>">

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                <div class="form-group">
                    <label>From (Airport Code)</label>
                    <input type="text" name="departure_id"
                           value="<%= searched ? searchOrigin : "" %>"
                           placeholder="e.g. <%= "return".equals(searchDirection) ? "LAX" : "SJC" %>" required>
                </div>
                <div class="form-group">
                    <label>To (Airport Code)</label>
                    <input type="text" name="arrival_id"
                           value="<%= searched ? searchDest : "" %>"
                           placeholder="e.g. <%= "return".equals(searchDirection) ? "SJC" : "LAX" %>" required>
                </div>
            </div>

            <div class="form-group">
                <label>Date</label>
                <input type="date" name="outbound_date"
                       value="<%= searched ? searchDate : ("return".equals(searchDirection) ? tripEndDate : tripStartDate) %>" required>
            </div>

            <div class="form-group">
                <label>Searching For</label>
                <select name="direction" style="width: 100%; padding: 13px 16px; border: 1px solid var(--border); border-radius: var(--radius); font-family: 'DM Sans', sans-serif; font-size: 0.95rem; color: var(--charcoal); background: var(--cream); outline: none;">
                    <option value="outbound" <%= (request.getParameter("direction") != null && request.getParameter("direction").equals("outbound")) ? "selected" : "" %>>Outbound Flight</option>
                    <option value="return" <%= (request.getParameter("direction") != null && request.getParameter("direction").equals("return")) ? "selected" : "" %>>Return Flight</option>
                </select>
            </div>

            <button type="submit" class="btn btn-primary">Search Flights</button>
        </form>
    </div>

    <% if (searchError != null) { %>
        <div class="card card-wide" style="margin-bottom: 24px;">
            <div class="alert alert-error"><%= searchError %></div>
        </div>
    <% } %>

    <% if (searched && flightResults.size() > 0) { %>
        <div class="card card-wide" style="margin-bottom: 24px;">
            <h2>Flight Results
                <% if (fromCache) { %>
                    <span style="font-size: 0.7rem; color: var(--text-muted); font-family: 'DM Sans', sans-serif; font-weight: 500;">(cached — prices may have changed)</span>
                <% } %>
            </h2>
            <div class="trips-grid" style="margin-top: 16px;">
                <% for (HashMap<String, String> flight : flightResults) { %>
                    <div class="trip-card" style="flex-direction: row; align-items: center; gap: 16px;">
                        <div class="trip-icon planned">&#9992;</div>
                        <div class="trip-details" style="flex: 1;">
                            <div class="trip-name"><%= flight.get("transport_name") %></div>
                            <div class="trip-route"><%= flight.get("departure_location") %> &rarr; <%= flight.get("arrival_destination") %></div>
                            <div class="trip-route"><%= flight.get("departure_time") %> &rarr; <%= flight.get("arrival_time") %></div>
                        </div>
                        <div style="text-align: right;">
                            <div class="trip-name" style="color: var(--accent); font-size: 1.1rem;">$<%= String.format("%.2f", Double.parseDouble(flight.get("base_cost"))) %></div>
                            <form action="select_transportation.jsp" method="POST" style="margin-top: 8px;">
                                <input type="hidden" name="tripId" value="<%= tripId %>">
                                <input type="hidden" name="transportID" value="<%= flight.get("transportID") %>">
                                <input type="hidden" name="direction" value="<%= searchDirection %>">
                                <button type="submit" class="btn btn-primary" style="padding: 6px 16px; font-size: 0.8rem;">Select</button>
                            </form>
                        </div>
                    </div>
                <% } %>
            </div>
        </div>
    <% } %>

    <% if (companyListings.size() > 0) { %>
        <div class="card card-wide" style="margin-bottom: 24px;">
            <h2>Special Listings</h2>
            <p style="color: var(--text-muted); font-weight: 500; font-size: 0.85rem; margin-top: 4px;">Posted by verified companies on Travelog.</p>
            <div class="trips-grid" style="margin-top: 16px;">
                <% for (HashMap<String, String> listing : companyListings) { %>
                    <div class="trip-card" style="flex-direction: row; align-items: center; gap: 16px;">
                        <div class="trip-icon booked">&#9992;</div>
                        <div class="trip-details" style="flex: 1;">
                            <div class="trip-name"><%= listing.get("transport_name") %></div>
                            <div class="trip-route"><%= listing.get("departure_location") %> &rarr; <%= listing.get("arrival_destination") %></div>
                            <div class="trip-route"><%= listing.get("departure_time") %> &rarr; <%= listing.get("arrival_time") %></div>
                        </div>
                        <div style="text-align: right;">
                            <div class="trip-name" style="color: var(--accent); font-size: 1.1rem;">$<%= String.format("%.2f", Double.parseDouble(listing.get("base_cost"))) %></div>
                            <form action="select_transportation.jsp" method="POST" style="margin-top: 8px;">
                                <input type="hidden" name="tripId" value="<%= tripId %>">
                                <input type="hidden" name="transportID" value="<%= listing.get("transportID") %>">
                                <input type="hidden" name="direction" value="<%= searchDirection %>">
                                <button type="submit" class="btn btn-primary" style="padding: 6px 16px; font-size: 0.8rem;">Select</button>
                            </form>
                        </div>
                    </div>
                <% } %>
            </div>
        </div>
    <% } %>

    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
</body>
</html>