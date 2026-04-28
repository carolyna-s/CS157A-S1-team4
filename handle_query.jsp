<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>
<%
    // Must be logged in
    String username = (String) session.getAttribute("username");
    Integer userID  = (Integer) session.getAttribute("userID");

    if (username == null) { // checks if user is logged in or not
        response.sendRedirect("login.jsp");//if not logged in send to login 
        return;
    }

    Connection con = null;// connnects the database
    PreparedStatement pstmt = null;// helps to execute the query
    ResultSet rs = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);// connects to the database

        // Verify the acting user is an admin
        pstmt = con.prepareStatement("SELECT userID FROM Admin WHERE userID = ?");
        pstmt.setInt(1, userID);// checks if the user is an admin or not
        rs = pstmt.executeQuery();// executes the query
        if (!rs.next()) {// if the user is not an admin, they get redirected to the regular dashboard
            con.close();
            response.sendRedirect("dashboard.jsp");//this will redirect if not an admin 
            return;
        }
        rs.close();
        pstmt.close();
    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) try { con.close(); } catch (Exception ex) {}
        response.sendRedirect("admin_dashboard.jsp");
        return;
    }

    // Read the queryID from the URL (e.g. handle_query.jsp?queryID=3)
    String queryIDParam = request.getParameter("queryID");
    if (queryIDParam == null) {
        if (con != null) try { con.close(); } catch (Exception ex) {}
        response.sendRedirect("admin_dashboard.jsp");
        return;
    }

    int queryID = 0;
    try {
        queryID = Integer.parseInt(queryIDParam);
    } catch (NumberFormatException e) {
        if (con != null) try { con.close(); } catch (Exception ex) {}
        response.sendRedirect("admin_dashboard.jsp");
        return;
    }

    // Fetch the full query details including who submitted it
    String subject = "", messageBody = "", queryStatus = "", submitterUsername = "", createdTimestamp = "";
    try {
        pstmt = con.prepareStatement(
            "SELECT sq.subject, sq.message_body, sq.query_status, sq.created_timestamp, u.username " +
            "FROM Support_Queries sq JOIN Users u ON sq.userID = u.userID " +//
            "WHERE sq.queryID = ?"// selects the query details and the username of the submitter based on the queryID
        );
        pstmt.setInt(1, queryID);
        rs = pstmt.executeQuery();
        if (rs.next()) {// if the query exists, store its details in variables to display on the page
            subject           = rs.getString("subject");
            messageBody       = rs.getString("message_body");
            queryStatus       = rs.getString("query_status");
            submitterUsername = rs.getString("username");
            createdTimestamp  = rs.getString("created_timestamp");
        }
        rs.close();
        pstmt.close();
    } catch (Exception e) {
        e.printStackTrace();
    }

    String success = request.getParameter("success");
    String error   = request.getParameter("error");
%>

<!DOCTYPE html> 
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Handle Query | Travelog</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div style="width: 100%; max-width: 820px; display: flex; justify-content: flex-end; gap: 12px; margin-bottom: -32px;">
        <a href="admin_dashboard.jsp" class="btn btn-secondary">Back to Admin Panel</a>
    </div>

    <div class="hero">
        <div class="duck-mark hero" style="margin-bottom: -8px;"></div>
        <h1 class="brand-title">Travelog<span class="accent-dot">.</span></h1>
        <p class="brand-subtitle">Support Query — Admin View</p>
    </div>

    <% if (success != null) { %>
        <div class="card card-wide" style="background: #e6f4ea; margin-bottom: 16px;">
            <p style="color: #2e7d32; font-weight: 600;"><%= success %></p>
        </div>
    <% } %>
    <% if (error != null) { %>
        <div class="card card-wide" style="background: #fdecea; margin-bottom: 16px;">
            <p style="color: #c62828; font-weight: 600;"><%= error %></p>
        </div>
    <% } %>

    <!-- Display the full query details -->
    <div class="card card-wide" style="margin-bottom: 24px;">
        <h2><%= subject %></h2>
        <p style="color: var(--text-muted); margin-top: 6px;">
            Submitted by <strong><%= submitterUsername %></strong> on <%= createdTimestamp %>
            &nbsp;|&nbsp; Status: <strong><%= queryStatus %></strong>
        </p>
        <p style="margin-top: 16px; line-height: 1.8;"><%= messageBody %></p>
    </div>

    <!-- Form to update the query status -->
    <div class="card card-wide">
        <h2>Update Status</h2>
        <form action="handle_query_process.jsp" method="POST" style="margin-top: 18px;">

            <!-- Pass the queryID so the process page knows which query to update -->
            <input type="hidden" name="queryID" value="<%= queryID %>">

            <!-- Dropdown to pick the new status; pre-selects the current one -->
            <label style="font-weight: 600;">New Status</label>
            <select name="newStatus" style="display:block; margin-top: 8px; margin-bottom: 16px; padding: 8px; border-radius: 6px; border: 1px solid #ccc; width: 100%;">
                <option value="in_progress" <%= queryStatus.equals("in_progress") ? "selected" : "" %>>In Progress</option>
                <option value="resolved"    <%= queryStatus.equals("resolved")    ? "selected" : "" %>>Resolved</option>
            </select>

            <button type="submit" class="btn btn-primary">Update Query</button>
        </form>
    </div>

    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
<%
    if (con != null) try { con.close(); } catch (Exception ex) {}
%>
</body>
</html>
