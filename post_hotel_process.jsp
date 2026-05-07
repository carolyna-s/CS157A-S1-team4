<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>
<%
    Integer userID = (Integer) session.getAttribute("userID");
    if (userID == null || !"company".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String hotelName   = request.getParameter("hotel_name");
    String location    = request.getParameter("location");
    String description = request.getParameter("description");
    String priceStr    = request.getParameter("price_per_night");
    String ratingStr   = request.getParameter("rating");

    if (hotelName == null || hotelName.trim().isEmpty() ||
        location == null  || location.trim().isEmpty()  ||
        priceStr == null  || priceStr.trim().isEmpty()) {
        response.sendRedirect("company_dashboard.jsp?error=Please+fill+in+all+required+fields.");
        return;
    }

    double price = 0;
    double rating = 0;
    try { price = Double.parseDouble(priceStr); } catch (Exception e) {
        response.sendRedirect("company_dashboard.jsp?error=Invalid+price.");
        return;
    }
    if (ratingStr != null && !ratingStr.trim().isEmpty()) {
        try { rating = Double.parseDouble(ratingStr); } catch (Exception e) {}
    }

    Connection con = null;
    PreparedStatement pstmt = null;
    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        pstmt = con.prepareStatement(
            "INSERT INTO Hotel_Listing (company_userID, hotel_name, location, description, rating, price_per_night, availability, listing_status, last_fetched) " +
            "VALUES (?, ?, ?, ?, ?, ?, 'available', 'active', NOW())",
            Statement.RETURN_GENERATED_KEYS
        );
        pstmt.setInt(1, userID);
        pstmt.setString(2, hotelName.trim());
        pstmt.setString(3, location.trim().toUpperCase());
        pstmt.setString(4, description != null ? description.trim() : "");
        pstmt.setDouble(5, rating);
        pstmt.setDouble(6, price);
        pstmt.executeUpdate();

        ResultSet keys = pstmt.getGeneratedKeys();
        int newHotelID = 0;
        if (keys.next()) newHotelID = keys.getInt(1);
        keys.close();
        pstmt.close();

        pstmt = con.prepareStatement("INSERT INTO Posts_Hotel (company_userID, hotelID) VALUES (?, ?)");
        pstmt.setInt(1, userID);
        pstmt.setInt(2, newHotelID);
        pstmt.executeUpdate();
        pstmt.close();

        con.close();
        response.sendRedirect("company_dashboard.jsp?success=Hotel+listing+posted.");
    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) try { con.close(); } catch (Exception ex) {}
        response.sendRedirect("company_dashboard.jsp?error=Failed+to+post+listing.");
    }
%>
