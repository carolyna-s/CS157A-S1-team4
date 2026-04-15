<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>
<%
    String username = (String) session.getAttribute("username");
    Integer userID = (Integer) session.getAttribute("userID");

    if (username == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    boolean hasTrips = false;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        pstmt = con.prepareStatement(
            "SELECT tripID, trip_name, start_location, destination, start_date, end_date, status " +
            "FROM Trip WHERE userID = ? " +
            "ORDER BY time_created DESC LIMIT 5"
        );
        pstmt.setInt(1, userID);
        rs = pstmt.executeQuery();
        hasTrips = rs.isBeforeFirst();
    } catch (Exception e) {
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard | Travelog</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div style="width: 100%; max-width: 820px; display: flex; justify-content: flex-end; gap: 12px; margin-bottom: -32px;">
        <a href="logout.jsp" class="btn btn-secondary">Logout</a>
        <a href="delete_account.jsp" class="btn btn-danger">Delete Account</a>
    </div>

    <div class="hero">
        <div class="duck-mark hero" style="margin-bottom: -8px;"></div>
        <h1 class="brand-title">Travelog<span class="accent-dot">.</span></h1>
        <p class="brand-subtitle">Welcome back, <%= username %>.</p>

    </div>

    <div class="card card-wide" style="margin-bottom: 24px;">
        <h2>Your Dashboard</h2>
        <p style="color: var(--text-muted); font-weight: 500; line-height: 1.8; margin-top: 12px;">
            Keep track of your trips, bookings, and travel plans all in one place.
        </p>
    </div>

    <div class="card card-wide" style="margin-bottom: 24px;">
        <h2>Quick Actions</h2>
        <div class="hero-actions" style="justify-content: flex-start; margin-top: 18px;">
            <a href="create_trip.jsp" class="btn btn-primary">Start a New Trip</a>
            <a href="view_trips.jsp" class="btn btn-secondary">View Trips</a>
        </div>
    </div>

    <div class="card card-wide">
        <h2>Recently Created</h2>
        <% if (!hasTrips) { %>
            <p style="color: var(--text-muted); font-weight: 500; line-height: 1.8; margin-top: 12px;">
                No trips yet. Create one to get started!
            </p>
        <% } else { %>
            <div class="trips-grid" style="margin-top: 16px;">
            <% while (rs.next()) {
                int tripId = rs.getInt("tripID");
                String status = rs.getString("status");
                if (status == null) status = "planned";
                String statusClass = status.toLowerCase();
            %>
                <a href="trip_details.jsp?tripId=<%= tripId %>" style="text-decoration: none; color: inherit;">
                    <div class="trip-card">
                        <div class="trip-icon <%= statusClass %>">📍</div>
                        <div class="trip-details">
                            <div class="trip-name"><%= rs.getString("trip_name") %></div>
                            <div class="trip-route"><%= rs.getString("start_location") %> &rarr; <%= rs.getString("destination") %></div>
                        </div>
                        <div class="trip-meta">
                            <div class="trip-dates"><%= rs.getString("start_date") %> to <%= rs.getString("end_date") %></div>
                            <div class="trip-status status-<%= statusClass %>"><%= status %></div>
                        </div>
                    </div>
                </a>
            <% } %>
            </div>
        <% }
            if (rs != null) try { rs.close(); } catch(Exception ex) {}
            if (pstmt != null) try { pstmt.close(); } catch(Exception ex) {}
            if (con != null) try { con.close(); } catch(Exception ex) {}
        %>
    </div>

    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4 — CS157A</p>
    </div>

</div>
</body>
</html>