<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>
<%
    Integer userID = (Integer) session.getAttribute("userID");
    if (userID == null || !"company".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    // pull form fields from the Post a Hotel Listing form on company_dashboard.jsp
    String hotelName    = request.getParameter("hotel_name");
    String location     = request.getParameter("location");
    String description  = request.getParameter("description");
    String priceStr     = request.getParameter("price_per_night");
    String ratingStr    = request.getParameter("rating");
    String discountStr  = request.getParameter("discount_percent");// optional
    String availability = request.getParameter("availability");// dropdown
    if (availability == null || availability.trim().isEmpty()) availability = "available"; // default

    if (hotelName == null || hotelName.trim().isEmpty() ||
        location == null  || location.trim().isEmpty()  ||
        priceStr == null  || priceStr.trim().isEmpty()) 
    {
        response.sendRedirect("company_dashboard.jsp?error=Please+fill+in+all+required+fields.");
        return;
    }

    double price = 0;
    double rating = 0;
    double discount = 0;
    try { price = Double.parseDouble(priceStr); } catch (Exception e) {
        response.sendRedirect("company_dashboard.jsp?error=Invalid+price.");
        return;
    }
    if (ratingStr != null && !ratingStr.trim().isEmpty()) {
        try { rating = Double.parseDouble(ratingStr); } catch (Exception e) {}
    }
    // discount is optional, so we only validate if they typed something (also has fixed range)
    if (discountStr != null && !discountStr.trim().isEmpty()) {
        try { discount = Double.parseDouble(discountStr); } catch (Exception e) {}
        if (discount < 0 || discount > 100) {
            response.sendRedirect("company_dashboard.jsp?error=Discount+must+be+between+0+and+100.");
            return;
        }
    }

    Connection con = null;
    PreparedStatement pstmt = null;
    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        pstmt = con.prepareStatement(
            "INSERT INTO Hotel_Listing (company_userID, hotel_name, location, description, rating, price_per_night, discount_percent, availability, listing_status, last_fetched) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active', NOW())",
            Statement.RETURN_GENERATED_KEYS
        );
        pstmt.setInt(1, userID);
        pstmt.setString(2, hotelName.trim());
        pstmt.setString(3, location.trim().toUpperCase());
        pstmt.setString(4, description != null ? description.trim() : "");
        pstmt.setDouble(5, rating);
        pstmt.setDouble(6, price);
        pstmt.setDouble(7, discount);
        pstmt.setString(8, availability);
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
