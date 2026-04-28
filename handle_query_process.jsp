<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>
<%
    // Must be logged in
    Integer userID = (Integer) session.getAttribute("userID");
    if (userID == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Read form values submitted from handle_query.jsp
    String queryIDParam = request.getParameter("queryID");
    String newStatus    = request.getParameter("newStatus"); // "in_progress" or "resolved"

    if (queryIDParam == null || newStatus == null) {
        response.sendRedirect("admin_dashboard.jsp?error=Invalid+request.");
        return;
    }

    int queryID = 0;
    try {
        queryID = Integer.parseInt(queryIDParam);// converts the queryID from String to int
    } catch (NumberFormatException e) {// if the queryID is not a valid integer, redirect back with an error
        response.sendRedirect("admin_dashboard.jsp?error=Invalid+query+ID.");
        return;    
    }

    // Only allow valid status values to prevent bad data being written to the DB
    if (!newStatus.equals("in_progress") && !newStatus.equals("resolved")) {
        response.sendRedirect("admin_dashboard.jsp?error=Invalid+status.");
        return;
    }

    Connection con = null;
    PreparedStatement pstmt = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // Verify the acting user is an admin
        pstmt = con.prepareStatement("SELECT userID FROM Admin WHERE userID = ?");
        pstmt.setInt(1, userID);
        ResultSet rs = pstmt.executeQuery();
        if (!rs.next()) {
            con.close();
            response.sendRedirect("dashboard.jsp");
            return;
        }
        rs.close();
        pstmt.close();

        // Update the query status; if resolving, also stamp the resolved_timestamp
        if (newStatus.equals("resolved")) {
            pstmt = con.prepareStatement(
                "UPDATE Support_Queries SET query_status = 'resolved', assigned_admin_userID = ?, resolved_timestamp = NOW() WHERE queryID = ?"
            );
        } else {
            // Mark as in_progress and assign this admin to the query
            pstmt = con.prepareStatement(
                "UPDATE Support_Queries SET query_status = 'in_progress', assigned_admin_userID = ? WHERE queryID = ?"
            );
        }
        pstmt.setInt(1, userID);
        pstmt.setInt(2, queryID);
        pstmt.executeUpdate();
        pstmt.close();

        // Insert into the Handles junction table to record which admin handled this query
        pstmt = con.prepareStatement(
            "INSERT INTO Handles (admin_userID, queryID) VALUES (?, ?)"
        );
        pstmt.setInt(1, userID);
        pstmt.setInt(2, queryID);
        pstmt.executeUpdate();
        pstmt.close();

        con.close();
        response.sendRedirect("admin_dashboard.jsp?success=Query+updated+successfully.");

    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) try { con.close(); } catch (Exception ex) {}
        response.sendRedirect("admin_dashboard.jsp?error=Database+error.");
    }
%>
