<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="WEB-INF/db_config.jsp" %>

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

    int tripId = 0;
    try {
        tripId = Integer.parseInt(tripIdParam);
    } catch (NumberFormatException e) {
        response.sendRedirect("view_trips.jsp");
        return;
    }

    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    String tripName = "";
    String startLocation = "";
    String destination = "";
    String startDate = "";
    String endDate = "";
    String status = "";

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        pstmt = con.prepareStatement(
            "SELECT trip_name, start_location, destination, start_date, end_date, status " +
            " FROM Trip WHERE tripID = ? AND userID = ? "
        );
        pstmt.setInt(1, tripId);
        pstmt.setInt(2, userID);
        rs = pstmt.executeQuery();

        if (rs.next()) {
            tripName = rs.getString("trip_name");
            startLocation = rs.getString("start_location");
            destination = rs.getString("destination");
            startDate = rs.getString("start_date");
            endDate = rs.getString("end_date");
            status = rs.getString("status");
        } else {
            response.sendRedirect("view_trips.jsp");
            return;
        }
        rs.close();
        pstmt.close();

        // Don't close con yet — reuse for transport query
    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("view_trips.jsp");
        return;
    }

    if (status == null) status = "planned";
    String statusClass = status.toLowerCase();

    // Load selected transportation for this trip
    java.util.ArrayList<java.util.HashMap<String, String>> selectedTransport = new java.util.ArrayList<>();
    try {
        if (con == null || con.isClosed()) {
            Class.forName(DB_DRIVER);
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        }
        pstmt = con.prepareStatement(
            "SELECT tt.*, tl.transport_name, tl.departure_location, tl.arrival_destination, " +
            "tl.departure_time, tl.arrival_time FROM Trip_Transportation tt " +
            "JOIN Transport_Listing tl ON tt.transportID = tl.transportID " +
            "WHERE tt.tripID = ? ORDER BY tt.trip_transport_sequence_num"
        );
        pstmt.setInt(1, tripId);
        rs = pstmt.executeQuery();
        while (rs.next()) {
            java.util.HashMap<String, String> t = new java.util.HashMap<>();
            t.put("seq", String.valueOf(rs.getInt("trip_transport_sequence_num")));
            t.put("transportID", String.valueOf(rs.getInt("transportID")));
            t.put("transport_name", rs.getString("transport_name"));
            t.put("departure_location", rs.getString("departure_location"));
            t.put("arrival_destination", rs.getString("arrival_destination"));
            t.put("departure_time", rs.getString("departure_time"));
            t.put("arrival_time", rs.getString("arrival_time"));
            t.put("price", rs.getString("price"));
            t.put("direction", rs.getString("direction"));
            t.put("booking_status", rs.getString("booking_status"));
            selectedTransport.add(t);
        }
        rs.close();
        pstmt.close();
    } 
    catch (Exception e) {
        e.printStackTrace();
    } 
    java.util.ArrayList<java.util.HashMap<String, String>> selectedHotels = new java.util.ArrayList<>();
    try{
        if (con == null || con.isClosed()){
            Class.forName(DB_DRIVER);
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        }
        pstmt = con.prepareStatement(
            "SELECT th.*, hl.hotel_name, hl.location, hl.thumbnail_url " +
            "FROM Trip_Hotels th " +
            "JOIN Hotel_Listing hl ON th.hotelID = hl.hotelID " +
            "WHERE th.tripID = ? ORDER BY th.trip_hotel_sequence_num " 
        );
        pstmt.setInt(1,tripId);
        rs=pstmt.executeQuery();
        while(rs.next()){
           java.util.HashMap<String, String> h = new java.util.HashMap<>();
            h.put("seq", String.valueOf(rs.getInt("trip_hotel_sequence_num")));
            h.put("hotelID", String.valueOf(rs.getInt("hotelID")));
            h.put("hotel_name", rs.getString("hotel_name"));
            h.put("location", rs.getString("location"));
            h.put("check_in_date", rs.getString("check_in_date"));
            h.put("check_out_date", rs.getString("check_out_date"));
            h.put("total_cost", rs.getString("total_cost"));
            h.put("booking_status", rs.getString("booking_status"));
            h.put("thumbnail_url", rs.getString("thumbnail_url"));
            selectedHotels.add(h); 
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
    <title>Travelog — <%= tripName %></title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div style="width: 100%; max-width: 820px; display: flex; justify-content: flex-end; gap: 12px; margin-bottom: -32px;">
        <a href="view_trips.jsp" class="btn btn-secondary">Back to Trips</a>
        <a href="dashboard.jsp" class="btn btn-secondary">Dashboard</a>
    </div>

    <div class="hero">
        <div class="duck-mark hero" style="margin-bottom: -8px;"></div>
        <h1 class="brand-title"><%= tripName %><span class="accent-dot">.</span></h1>
        <p class="brand-subtitle"><%= startLocation %> &rarr; <%= destination %></p>
        <div style="margin-top: 12px;">
            <span class="trip-status status-<%= statusClass %>"><%= status %></span>
        </div>
    </div>

    <div class="card card-wide" style="margin-bottom: 24px;">
        <h2>Trip Details</h2>

        <%
            String success = request.getParameter("success");
            if (success != null) {
        %>
            <div class="alert alert-success" style="margin-top: 16px;"><%= success %></div>
        <%
            }
            String error = request.getParameter("error");
            if (error != null) {
        %>
            <div class="alert alert-error" style="margin-top: 16px;"><%= error %></div>
        <%
            }
        %>

        <form action="edit_trip_process.jsp" method="POST" style="margin-top: 18px;">
            <input type="hidden" name="tripId" value="<%= tripId %>">

            <div class="form-group">
                <label>Trip Name</label>
                <input type="text" name="trip_name" value="<%= tripName %>" required>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                <div class="form-group">
                    <label>From</label>
                    <input type="text" name="start_location" value="<%= startLocation %>" required>
                </div>
                <div class="form-group">
                    <label>To</label>
                    <input type="text" name="destination" value="<%= destination %>" required>
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                <div class="form-group">
                    <label>Start Date</label>
                    <input type="date" name="start_date" value="<%= startDate %>" required>
                </div>
                <div class="form-group">
                    <label>End Date</label>
                    <input type="date" name="end_date" value="<%= endDate %>" required>
                </div>
            </div>

            <button type="submit" class="btn btn-primary">Save Changes</button>
        </form>
    </div>

    <%
        java.util.ArrayList<java.util.HashMap<String, String>> outboundFlights = new java.util.ArrayList<>();
        java.util.ArrayList<java.util.HashMap<String, String>> returnFlights = new java.util.ArrayList<>();
        for (java.util.HashMap<String, String> t : selectedTransport) {
            if ("return".equals(t.get("direction"))) {
                returnFlights.add(t);
            } else {
                outboundFlights.add(t);
            }
        }
    %>

    <div class="card card-wide" style="margin-bottom: 24px;">
        <h2>Outbound Flight</h2>
        <% if (outboundFlights.isEmpty()) { %>
            <p style="color: var(--text-muted); font-weight: 500; line-height: 1.8; margin-top: 12px;">
                No outbound flight selected yet.
            </p>
        <% } else { %>
            <div class="trips-grid" style="margin-top: 16px;">
                <% for (java.util.HashMap<String, String> t : outboundFlights) { %>
                    <div class="trip-card">
                        <div class="trip-icon planned">&#9992;</div>
                        <div class="trip-details">
                            <div class="trip-name"><%= t.get("transport_name") %></div>
                            <div class="trip-route"><%= t.get("departure_location") %> &rarr; <%= t.get("arrival_destination") %></div>
                            <div class="trip-route"><%= t.get("departure_time") %> &rarr; <%= t.get("arrival_time") %></div>
                        </div>
                        <div class="trip-meta">
                            <div class="trip-name" style="color: var(--accent);">$<%= String.format("%.2f", Double.parseDouble(t.get("price"))) %></div>
                            <div class="trip-status status-<%= t.get("booking_status") %>"><%= t.get("booking_status") %></div>
                            <a href="remove_transportation.jsp?tripId=<%= tripId %>&seq=<%= t.get("seq") %>&transportID=<%= t.get("transportID") %>"
                               class="btn btn-danger" style="padding: 4px 12px; font-size: 0.75rem; margin-top: 6px;">Remove</a>
                        </div>
                    </div>
                <% } %>
            </div>
        <% } %>
        <div class="hero-actions" style="justify-content: flex-start; margin-top: 18px;">
            <a href="browse_transportation.jsp?tripId=<%= tripId %>&direction=outbound" class="btn btn-primary">Browse Outbound Flights</a>
        </div>
    </div>

    <div class="card card-wide" style="margin-bottom: 24px;">
        <h2>Return Flight</h2>
        <% if (returnFlights.isEmpty()) { %>
            <p style="color: var(--text-muted); font-weight: 500; line-height: 1.8; margin-top: 12px;">
                No return flight selected yet.
            </p>
        <% } else { %>
            <div class="trips-grid" style="margin-top: 16px;">
                <% for (java.util.HashMap<String, String> t : returnFlights) { %>
                    <div class="trip-card">
                        <div class="trip-icon planned">&#9992;</div>
                        <div class="trip-details">
                            <div class="trip-name"><%= t.get("transport_name") %></div>
                            <div class="trip-route"><%= t.get("departure_location") %> &rarr; <%= t.get("arrival_destination") %></div>
                            <div class="trip-route"><%= t.get("departure_time") %> &rarr; <%= t.get("arrival_time") %></div>
                        </div>
                        <div class="trip-meta">
                            <div class="trip-name" style="color: var(--accent);">$<%= String.format("%.2f", Double.parseDouble(t.get("price"))) %></div>
                            <div class="trip-status status-<%= t.get("booking_status") %>"><%= t.get("booking_status") %></div>
                            <a href="remove_transportation.jsp?tripId=<%= tripId %>&seq=<%= t.get("seq") %>&transportID=<%= t.get("transportID") %>"
                               class="btn btn-danger" style="padding: 4px 12px; font-size: 0.75rem; margin-top: 6px;">Remove</a>
                        </div>
                    </div>
                <% } %>
            </div>
        <% } %>
        <div class="hero-actions" style="justify-content: flex-start; margin-top: 18px;">
            <a href="browse_transportation.jsp?tripId=<%= tripId %>&direction=return" class="btn btn-primary">Browse Return Flights</a>
        </div>
    </div>
    <div class="card card-wide" style="margin-bottom: 24px;">
        <h2>Lodging</h2>
        <% if (selectedHotels.isEmpty()) { %>
            <p style="color: var(--text-muted); font-weight: 500; line-height: 1.8; margin-top: 12px;">
                No hotels selected yet.
            </p>
        <% } else { %>
            <div class="trips-grid" style="margin-top: 16px;">
                <% for (java.util.HashMap<String, String> h : selectedHotels) { %>
                    <div class="trip-card">
                        <% if (h.get("thumbnail_url") != null && !h.get("thumbnail_url").isEmpty()) { %>
                            <div style="width: 48px; height: 48px; border-radius: 8px; overflow: hidden; flex-shrink: 0; display: flex; align-items: center; justify-content: center; background: #f0f0f0;">
                                <img src="<%= h.get("thumbnail_url") %>" alt="Hotel Thumbnail" style="width: 100%; height: 100%; object-fit: cover;">
                            </div>
                        <% } else { %>
                            <div class="trip-icon planned">&#127976;</div>
                        <% } %>
                        <div class="trip-details">
                            <div class="trip-name"><%= h.get("hotel_name") %></div>
                            <div class="trip-route"><%= h.get("location") %></div>
                            <div class="trip-route"><%= h.get("check_in_date") %> &rarr; <%= h.get("check_out_date") %></div>
                        </div>
                        <div class="trip-meta">
                            <div class="trip-name" style="color: var(--accent);">$<%= String.format("%.2f", Double.parseDouble(h.get("total_cost"))) %></div>
                            <div class="trip-status status-<%= h.get("booking_status") %>"><%= h.get("booking_status") %></div>
                            <a href="remove_hotel.jsp?tripId=<%= tripId %>&seq=<%= h.get("seq") %>&hotelID=<%= h.get("hotelID") %>"
                               class="btn btn-danger" style="padding: 4px 12px; font-size: 0.75rem; margin-top: 6px;">Remove</a>
                        </div>
                    </div>
                <% } %>
            </div>
        <% } %>
        <div class="hero-actions" style="justify-content: flex-start; margin-top: 18px;">
            <a href="browse_hotels.jsp?tripId=<%= tripId %>" class="btn btn-primary">Browse Hotels</a>
        </div>
    </div>

    <% if (!"cancelled".equals(status)) { %>
    <div class="card card-wide" style="margin-bottom: 24px;">
        <h2>Cancel Trip</h2>
        <p style="color: var(--text-muted); font-weight: 500; line-height: 1.8; margin-top: 12px;">
            Cancelling this trip cannot be undone.
        </p>
        <form action="cancel_trip_process.jsp" method="POST" style="margin-top: 18px;"
            onsubmit="return confirm('Are you sure you want to cancel this trip?');">
        <input type="hidden" name="tripId" value="<%= tripId %>">
        <button type="submit" class="btn btn-danger">Cancel Trip</button>
    </form>
    </div>
    <% } %>
    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
</body>
</html>