<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="WEB-INF/db_config.jsp" %>

<%
    String username = (String) session.getAttribute("username");

    if (username == null) {
        response.sendRedirect("login.jsp");
        return;
    }

  
    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try 
    {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        pstmt = con.prepareStatement(
            "SELECT * " +
            "FROM Users u " +
            "JOIN Traveler trv ON u.userID = trv.userID " +
            "JOIN Trip t ON u.userID = t.userID " +
            "WHERE u.username = ? "
        );
        pstmt.setString(1,username);
        rs=pstmt.executeQuery();

    }
   catch (Exception e) {
        e.printStackTrace();
        out.println("Database connection error: " + e.getMessage());
    }

%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Travelog — Register</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div class="card card-wide">
        <div class="card-header">
            <div class="duck-mark large"></div>
            <h1 class="brand-title" style="font-size: 2rem;">Hello  <%= username %><span class="accent-dot">.</span></h1>
            <p class="brand-subtitle">Viewing your trips.</p>
        </div>

        <%
            String error = request.getParameter("error");
            if (error != null) {
        %>
            <div class="alert alert-error"><%= error %></div>
        <%
            }
        %>

        <div class="trips-grid">
        <% 
        while (rs.next()) { 
            int tripId = rs.getInt("tripID");
            String status = rs.getString("status");
            if (status == null) status = "planned"; // default fallback
            String statusClass = status.toLowerCase();
        %>
            <div class="trip-card" style="flex-direction: column; align-items: stretch; padding: 0;">
                <div style="display: flex; align-items: center; gap: 16px; padding: 18px 24px; cursor: pointer;" onclick="toggleDrawer(<%= tripId %>)">
                    
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

                <div class="trip-drawer" id="drawer-<%= tripId %>" style="display: none; padding: 18px 24px; border-top: 1px solid rgba(26, 26, 26, 0.08); background: #FAF6F1;">
                    <div class="hero-actions" style="margin-top: 0;">
                        <a href="transportation_placehold.jsp?tripId=<%= tripId %>" class="btn btn-secondary btn-sm">Transportation Options</a>
                        <a href="lodging_placehold.jsp?tripId=<%= tripId %>" class="btn btn-secondary btn-sm">Lodging</a>
                        
                    </div>
                </div>
            </div>
        <% } %>
        </div>

        <div class="form-divider">or</div>

      <div class="button-container">
    <div class="hero-actions">
        <a href="dashboard.jsp" class="btn btn-secondary btn-sm">Dashboard</a>
        <!-- <a href="transportation_placehold.jsp" class="btn btn-secondary btn-sm">Transportation</a>
        <a href="lodging_placehold.jsp" class="btn btn-secondary btn-sm">Lodging</a> -->
    </div>

</div>
    </div>

    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
    <script>
        function toggleDrawer(tripId) {
            // Find the specific drawer holding the buttons for this trip
            const drawer = document.getElementById('drawer-' + tripId);
            
            // Toggle it between open and closed
            if (drawer.style.display === "none" || drawer.style.display === "") {
                drawer.style.display = "block";  // Open it up
            } else {
                drawer.style.display = "none";   // Hide it again
            }
        }
    </script>
</body>

</body>
</html>