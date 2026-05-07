<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="WEB-INF/db_config.jsp" %>

<%
    Integer userID = (Integer) session.getAttribute("userID");


    if (userID == null) {
        response.sendRedirect("login.jsp?error=Invalid+Session.+Please+login+again.");
        return;
    }
    String tripIdParam= request.getParameter("tripId");
    String totalCostParam = request.getParameter("grandTotal");
    String paymentMethod = request.getParameter("payment_method");
    if (paymentMethod == null || paymentMethod.trim().isEmpty()) paymentMethod = "visa";

    if (tripIdParam == null || totalCostParam == null) {
        response.sendRedirect("view_trips.jsp");
        return;
    }

    int tripId = Integer.parseInt(tripIdParam);
    double amount = 0.0;
    try {
        amount = Double.parseDouble(totalCostParam);
    } catch (NumberFormatException e) {
        amount = 0.0;
    }
    
    Connection con = null;
    PreparedStatement pstmt = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        //insert record into Payments table
        pstmt = con.prepareStatement(
            "INSERT INTO Payments (tripID, userID, amount, payment_method, payment_status, payment_timestamp) " +
            "VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)"
        );
        pstmt.setInt(1, tripId);
        pstmt.setInt(2, userID);
        pstmt.setDouble(3, amount);
        pstmt.setString(4, paymentMethod);
        pstmt.setString(5, "paid");
        pstmt.executeUpdate();
        pstmt.close();
        //update status in trip table
        pstmt = con.prepareStatement("UPDATE Trip SET status = 'booked' WHERE tripID = ? AND userID = ?");
        pstmt.setInt(1, tripId);
        pstmt.setInt(2, userID);
        pstmt.executeUpdate();
        pstmt.close();
        //update status in hotels table
        pstmt = con.prepareStatement("UPDATE Trip_Hotels SET booking_status = 'booked' WHERE tripID = ?");
        pstmt.setInt(1, tripId);
        pstmt.executeUpdate();
        pstmt.close();
        //update status in transportaiton table
        pstmt = con.prepareStatement("UPDATE Trip_Transportation SET booking_status = 'booked' WHERE tripID = ?");
        pstmt.setInt(1, tripId);
        pstmt.executeUpdate();
        pstmt.close();

        con.close();

        response.sendRedirect("receipt.jsp?tripId=" + tripId);

    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("confirm_trip_details.jsp?tripId=" + tripId + "&error=Payment+failed.");
    }
%>