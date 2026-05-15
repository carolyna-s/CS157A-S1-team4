<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>
<%
    // company-only page which means both checks required (logged in + actually a company)
    Integer userID = (Integer) session.getAttribute("userID");
    if (userID == null || !"company".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    // form fields from the inline delete form on company_dashboard.jsp
    String type     = request.getParameter("type"); // hotel or transport
    String idParam  = request.getParameter("listingID");
    String password = request.getParameter("password");

    // password is required per spec (cant delete a listing w/o reconfirm)
    if (type == null || idParam == null || password == null || password.trim().isEmpty()) {
        response.sendRedirect("company_dashboard.jsp?error=Password+required+to+delete+listing.");
        return;
    }

    int listingID;
    try {
        listingID = Integer.parseInt(idParam);
    } catch (NumberFormatException e) {
        response.sendRedirect("company_dashboard.jsp?error=Invalid+listing.");
        return;
    }

    // hash the password
    String hashedPassword;
    try {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        byte[] hashBytes = digest.digest(password.getBytes(StandardCharsets.UTF_8));
        StringBuilder hex = new StringBuilder();
        for (byte b : hashBytes) {
            String h = Integer.toHexString(0xff & b);
            if (h.length() == 1) hex.append('0');
            hex.append(h);
        }
        hashedPassword = hex.toString();
    } catch (Exception e) {
        response.sendRedirect("company_dashboard.jsp?error=Server+error.");
        return;
    }

    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // stop if hash does not match
        pstmt = con.prepareStatement("SELECT userID FROM Users WHERE userID = ? AND password = ?");
        pstmt.setInt(1, userID);
        pstmt.setString(2, hashedPassword);
        rs = pstmt.executeQuery();
        if (!rs.next()) {
            rs.close(); 
            pstmt.close(); 
            con.close();
            response.sendRedirect("company_dashboard.jsp?error=Incorrect+password.+Deletion+cancelled.");
            return;
        }
        rs.close();
        pstmt.close();

        // we use archive status (so ppl who already booked still see it)
        String table = "hotel".equals(type) ? "Hotel_Listing" : "Transport_Listing";
        String idCol = "hotel".equals(type) ? "hotelID" : "transportID";

        // only current company can delete their own listing (not others), update stameent below
        pstmt = con.prepareStatement(
            "UPDATE " + table + " SET listing_status = 'archived' " +
            "WHERE " + idCol + " = ? AND company_userID = ?"
        );
        pstmt.setInt(1, listingID);
        pstmt.setInt(2, userID);
        int rows = pstmt.executeUpdate();
        pstmt.close();
        con.close();

        if (rows == 0) {
            response.sendRedirect("company_dashboard.jsp?error=Listing+not+found.");
        } else {
            response.sendRedirect("company_dashboard.jsp?success=Listing+archived.");
        }
    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) try { con.close(); } catch (Exception ex) {}
        response.sendRedirect("company_dashboard.jsp?error=Failed+to+archive+listing.");
    }
%>
