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

    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // Verify the acting user is an admin
        pstmt = con.prepareStatement("SELECT userID FROM Admin WHERE userID = ?");
        pstmt.setInt(1, userID);
        rs = pstmt.executeQuery();
        if (!rs.next()) {
            // Not an admin — redirect back to regular dashboard
            con.close();
            response.sendRedirect("dashboard.jsp");
            return;
        }
        rs.close();
        pstmt.close();
    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) try { con.close(); } catch (Exception ex) {}
        response.sendRedirect("admin_dashboard.jsp?error=Database+error.");
        return;
    }

    // Read the form values submitted from admin_dashboard.jsp
    String companyUserIDParam = request.getParameter("companyUserID");
    String decision           = request.getParameter("decision"); // "approved" or "rejected"

    // Validate that both values exist and decision is one of the two allowed values
    if (companyUserIDParam == null || decision == null ||
        (!decision.equals("approved") && !decision.equals("rejected"))) {
        if (con != null) try { con.close(); } catch (Exception ex) {}
        response.sendRedirect("admin_dashboard.jsp?error=Invalid+request.");
        return;
    }

    int companyUserID = 0;
    try {
        companyUserID = Integer.parseInt(companyUserIDParam);
    } catch (NumberFormatException e) {
        if (con != null) try { con.close(); } catch (Exception ex) {}
        response.sendRedirect("admin_dashboard.jsp?error=Invalid+company+ID.");
        return;
    }

    try {
        //Update the company's approval_status and stamp the verification date
        pstmt = con.prepareStatement(
            "UPDATE Company SET approval_status = ?, verification_date = NOW() WHERE userID = ?"
        );
        pstmt.setString(1, decision);
        pstmt.setInt(2, companyUserID);
        pstmt.executeUpdate();
        pstmt.close();

        // Insert a record into Company_Approval_Reviews to log the decision
        pstmt = con.prepareStatement(
            "INSERT INTO Company_Approval_Reviews (company_userID, admin_userID, decision, review_timestamp) " +
            "VALUES (?, ?, ?, NOW())"
        );
        pstmt.setInt(1, companyUserID);
        pstmt.setInt(2, userID); // the admin who made the decision
        pstmt.setString(3, decision);
        pstmt.executeUpdate();
        pstmt.close();

        //  Get the reviewID we just created so we can insert into the junction tables
        pstmt = con.prepareStatement(
            "SELECT reviewID FROM Company_Approval_Reviews " +
            "WHERE company_userID = ? AND admin_userID = ? ORDER BY review_timestamp DESC LIMIT 1"
        );
        pstmt.setInt(1, companyUserID);
        pstmt.setInt(2, userID);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            int reviewID = rs.getInt("reviewID");
            rs.close();
            pstmt.close();

            // Log which admin created this review in the Reviews_Company junction table
            pstmt = con.prepareStatement(
                "INSERT INTO Reviews_Company (admin_userID, reviewID) VALUES (?, ?)"
            );
            pstmt.setInt(1, userID);
            pstmt.setInt(2, reviewID);
            pstmt.executeUpdate();
            pstmt.close();

            // Log which company was reviewed in the Reviewed_For junction table
            pstmt = con.prepareStatement(
                "INSERT INTO Reviewed_For (company_userID, reviewID) VALUES (?, ?)"
            );
            pstmt.setInt(1, companyUserID);
            pstmt.setInt(2, reviewID);
            pstmt.executeUpdate();
            pstmt.close();
        }

        con.close();
        response.sendRedirect("admin_dashboard.jsp?success=Company+" + decision + "+successfully.");

    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) try { con.close(); } catch (Exception ex) {}
        // Show the actual SQL error so we can debug it
        String errMsg = e.getMessage() != null ? e.getMessage().replace(" ", "+") : "Unknown+error";
        response.sendRedirect("admin_dashboard.jsp?error=" + errMsg);
    }
%>
