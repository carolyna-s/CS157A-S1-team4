<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>
<%
    String username       = (String) session.getAttribute("username");
    String companyName    = (String) session.getAttribute("companyName");
    String approvalStatus = (String) session.getAttribute("approvalStatus");
    Integer userID        = (Integer) session.getAttribute("userID");

    if (username == null || !"company".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Re-fetch approval status and business type in case it changed since login
    String businessType = "";
    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        pstmt = con.prepareStatement("SELECT approval_status, business_type FROM Company WHERE userID = ?");
        pstmt.setInt(1, userID);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            approvalStatus = rs.getString("approval_status");
            businessType   = rs.getString("business_type");
            session.setAttribute("approvalStatus", approvalStatus);
        }
        rs.close();
        pstmt.close();
        con.close();
    } catch (Exception e) { e.printStackTrace(); }

    String success = request.getParameter("success");
    String error   = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Company Portal | Travelog</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div style="width:100%; max-width:820px; display:flex; justify-content:flex-end; margin-bottom:-32px;">
        <a href="logout.jsp" class="btn btn-secondary">Logout</a>
    </div>

    <div class="hero">
        <div class="duck-mark hero" style="margin-bottom:-8px;"></div>
        <h1 class="brand-title">Travelog<span class="accent-dot">.</span></h1>
        <p class="brand-subtitle">Company Portal — <%= companyName %></p>
    </div>

    <% if (success != null) { %>
        <div class="card card-wide" style="background:#e6f4ea; margin-bottom:16px;">
            <p style="color:#2e7d32; font-weight:600;"><%= success %></p>
        </div>
    <% } %>
    <% if (error != null) { %>
        <div class="card card-wide" style="background:#fdecea; margin-bottom:16px;">
            <p style="color:#c62828; font-weight:600;"><%= error %></p>
        </div>
    <% } %>

    <% if ("pending".equals(approvalStatus)) { %>
        <div class="card card-wide">
            <h2>Awaiting Approval</h2>
            <p style="color:var(--text-muted); font-weight:500; margin-top:12px;">
                Your company account is pending admin approval. You will be notified once reviewed.
            </p>
        </div>

    <% } else if ("rejected".equals(approvalStatus)) { %>
        <div class="card card-wide">
            <h2>Application Rejected</h2>
            <p style="color:#c62828; font-weight:500; margin-top:12px;">
                Your company application was rejected. Please contact support.
            </p>
        </div>

    <% } else if ("approved".equals(approvalStatus)) { %>

        <% if ("hotel".equals(businessType) || "both".equals(businessType)) { %>
        <div class="card card-wide" style="margin-bottom:24px;">
            <h2>Post a Hotel Listing</h2>
            <form action="post_hotel_process.jsp" method="POST" style="margin-top:18px;">
                <div class="form-group">
                    <label>Hotel Name</label>
                    <input type="text" name="hotel_name" placeholder="e.g. Marriott Downtown" required>
                </div>
                <div class="form-group">
                    <label>Location (City)</label>
                    <input type="text" name="location" placeholder="e.g. San Jose" required>
                </div>
                <div class="form-group">
                    <label>Description</label>
                    <textarea name="description" rows="3" placeholder="Brief description..."
                        style="width:100%; padding:10px; border-radius:8px; border:1px solid #ccc; font-family:inherit; resize:vertical;"></textarea>
                </div>
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                    <div class="form-group">
                        <label>Price per Night (USD)</label>
                        <input type="number" name="price_per_night" step="0.01" min="0" placeholder="e.g. 149.99" required>
                    </div>
                    <div class="form-group">
                        <label>Rating (0–5)</label>
                        <input type="number" name="rating" step="0.1" min="0" max="5" placeholder="e.g. 4.2">
                    </div>
                </div>
                <button type="submit" class="btn btn-primary">Post Hotel</button>
            </form>
        </div>
        <% } %>

        <% if ("transportation".equals(businessType) || "both".equals(businessType)) { %>
        <div class="card card-wide" style="margin-bottom:24px;">
            <h2>Post a Transportation Listing</h2>
            <form action="post_transportation_process.jsp" method="POST" style="margin-top:18px;">
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                    <div class="form-group">
                        <label>Transport Name</label>
                        <input type="text" name="transport_name" placeholder="e.g. United Airlines UA 123" required>
                    </div>
                    <div class="form-group">
                        <label>Type</label>
                        <select name="transport_type" required style="width:100%; padding:10px; border-radius:8px; border:1px solid #ccc;">
                            <option value="plane">Plane</option>
                            <option value="bus">Bus</option>
                            <option value="train">Train</option>
                        </select>
                    </div>
                </div>
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                    <div class="form-group">
                        <label>Departure</label>
                        <input type="text" name="departure_location" placeholder="e.g. SJC" required>
                    </div>
                    <div class="form-group">
                        <label>Arrival</label>
                        <input type="text" name="arrival_destination" placeholder="e.g. LAX" required>
                    </div>
                </div>
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                    <div class="form-group">
                        <label>Departure Time</label>
                        <input type="datetime-local" name="departure_time" required>
                    </div>
                    <div class="form-group">
                        <label>Arrival Time</label>
                        <input type="datetime-local" name="arrival_time" required>
                    </div>
                </div>
                <div class="form-group">
                    <label>Base Cost (USD)</label>
                    <input type="number" name="base_cost" step="0.01" min="0" placeholder="e.g. 299.00" required>
                </div>
                <button type="submit" class="btn btn-primary">Post Transportation</button>
            </form>
        </div>
        <% } %>

    <% } %>

    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
</body>
</html>
