<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>
<%
    // Check that someone is logged in
    String username = (String) session.getAttribute("username");
    Integer userID  = (Integer) session.getAttribute("userID");

    if (username == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    boolean isAdmin = false;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // Check if the logged-in user exists in the Admin table
        pstmt = con.prepareStatement("SELECT userID FROM Admin WHERE userID = ?");
        pstmt.setInt(1, userID);
        rs = pstmt.executeQuery();
        isAdmin = rs.next();
        rs.close();
        pstmt.close();
    } catch (Exception e) {
        e.printStackTrace();
    }

    // If not an admin, kick them back to the regular dashboard
    if (!isAdmin) {
        if (con != null) try { con.close(); } catch (Exception ex) {}
        response.sendRedirect("dashboard.jsp");
        return;
    }

    // Fetch all companies with approval_status = 'pending'
    ResultSet pendingCompanies = null;
    try {
        pstmt = con.prepareStatement(
            "SELECT c.userID, c.name, c.business_type, c.phone, u.email " +
            "FROM Company c JOIN Users u ON c.userID = u.userID " +
            "WHERE c.approval_status = 'pending'"
        );
        pendingCompanies = pstmt.executeQuery();
    } catch (Exception e) {
        e.printStackTrace();
    }

    // Fetch all support queries that are not yet resolved
    ResultSet openQueries = null;
    try {
        PreparedStatement pstmt2 = con.prepareStatement(
            "SELECT sq.queryID, sq.subject, sq.query_status, sq.created_timestamp, u.username " //selects the queryID, subject, status, created timestamp and username of the person who submitted the query
            +"FROM Support_Queries sq JOIN Users u ON sq.userID = u.userID " //joins the Support_Queries table with the Users table to get the username of the submitter
            + "WHERE sq.query_status != 'resolved' " //only fetches queries that are not resolved
            +"ORDER BY sq.created_timestamp ASC"//orders the queries by the time they were created, oldest first
        );
        openQueries = pstmt2.executeQuery();
    } catch (Exception e) {// if there's an error, print the stack trace for debugging
        e.printStackTrace();
    }

    // Read success/error messages passed in the URL after a redirect
    String success = request.getParameter("success");
    String error   = request.getParameter("error");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard | Travelog</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div style="width: 100%; max-width: 820px; display: flex; justify-content: flex-end; gap: 12px; margin-bottom: -32px;">
        <a href="logout.jsp" class="btn btn-secondary">Logout</a>
    </div>

    <div class="hero">
        <div class="duck-mark hero" style="margin-bottom: -8px;"></div>
        <h1 class="brand-title">Travelog<span class="accent-dot">.</span></h1>
        <p class="brand-subtitle">Admin Panel — <%= username %></p>
    </div>

    <!-- Show success or error banners if redirected here with a message -->
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

    <!--  Companies waiting for approval -->
    <div class="card card-wide" style="margin-bottom: 24px;">
        <h2>Pending Company Approvals</h2>
        <% if (pendingCompanies == null || !pendingCompanies.isBeforeFirst()) { %>
            <p style="color: var(--text-muted); margin-top: 12px;">No companies awaiting approval.</p>
        <% } else { %>
            <table style="width:100%; border-collapse: collapse; margin-top: 16px;">
                <thead>
                    <tr style="text-align:left; border-bottom: 2px solid #eee;">
                        <th style="padding: 8px;">Company Name</th>
                        <th style="padding: 8px;">Type</th>
                        <th style="padding: 8px;">Email</th>
                        <th style="padding: 8px;">Phone</th>
                        <th style="padding: 8px;">Action</th>
                    </tr>
                </thead>
                <tbody>
                <% while (pendingCompanies.next()) { %>
                    <tr style="border-bottom: 1px solid #f0f0f0;">
                        <td style="padding: 8px;"><%= pendingCompanies.getString("name") %></td>
                        <td style="padding: 8px;"><%= pendingCompanies.getString("business_type") %></td>
                        <td style="padding: 8px;"><%= pendingCompanies.getString("email") %></td>
                        <td style="padding: 8px;"><%= pendingCompanies.getString("phone") != null ? pendingCompanies.getString("phone") : "—" %></td>
                        <td style="padding: 8px;">
                            <!-- Approve: sends companyUserID and decision=approved to review_company_process.jsp -->
                            <form action="review_company_process.jsp" method="POST" style="display:inline;">
                                <input type="hidden" name="companyUserID" value="<%= pendingCompanies.getInt("userID") %>">
                                <input type="hidden" name="decision" value="approved">
                                <button type="submit" class="btn btn-primary" style="padding: 4px 12px; font-size: 13px;">Approve</button>
                            </form>
                            <!-- Reject: same but decision=rejected -->
                            <form action="review_company_process.jsp" method="POST" style="display:inline; margin-left: 6px;">
                                <input type="hidden" name="companyUserID" value="<%= pendingCompanies.getInt("userID") %>">
                                <input type="hidden" name="decision" value="rejected">
                                <button type="submit" class="btn btn-danger" style="padding: 4px 12px; font-size: 13px;">Reject</button>
                            </form>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        <% } %>
    </div>

    <!-- Section 2: Open and in-progress support queries -->
    <div class="card card-wide">
        <h2>Open Support Queries</h2>
        <% if (openQueries == null || !openQueries.isBeforeFirst()) { %>
            <p style="color: var(--text-muted); margin-top: 12px;">No open queries.</p>
        <% } else { %>
            <table style="width:100%; border-collapse: collapse; margin-top: 16px;">
                <thead>
                    <tr style="text-align:left; border-bottom: 2px solid #eee;">
                        <th style="padding: 8px;">User</th>
                        <th style="padding: 8px;">Subject</th>
                        <th style="padding: 8px;">Status</th>
                        <th style="padding: 8px;">Submitted</th>
                        <th style="padding: 8px;">Action</th>
                    </tr>
                </thead>
                <tbody>
                <% while (openQueries.next()) { %>
                    <tr style="border-bottom: 1px solid #f0f0f0;">
                        <td style="padding: 8px;"><%= openQueries.getString("username") %></td>
                        <td style="padding: 8px;"><%= openQueries.getString("subject") %></td>
                        <td style="padding: 8px;"><%= openQueries.getString("query_status") %></td>
                        <td style="padding: 8px;"><%= openQueries.getString("created_timestamp") %></td>
                        <td style="padding: 8px;">
                            <!-- Links to handle_query.jsp with the queryID in the URL -->
                            <a href="handle_query.jsp?queryID=<%= openQueries.getInt("queryID") %>" class="btn btn-secondary" style="padding: 4px 12px; font-size: 13px;">View & Resolve</a>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        <% } %>
    </div>

    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
<%
    // Close all DB resources
    if (pendingCompanies != null) try { pendingCompanies.close(); } catch (Exception ex) {}
    if (openQueries != null)      try { openQueries.close(); }      catch (Exception ex) {}
    if (con != null)              try { con.close(); }               catch (Exception ex) {}
%>
</body>
</html>
