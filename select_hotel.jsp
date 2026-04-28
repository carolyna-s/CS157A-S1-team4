<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="WEB-INF/db_config.jsp" %>

<%
    Integer userID = (Integer) session.getAttribute("userID");

    if (userID == null) {
        response.sendRedirect("login.jsp?error=Invalid+Session.+Please+login+again.");
        return;
    }

    String tripIdParam = request.getParameter("tripId");
    String hotelIDParam = request.getParameter("hotelID");
    String inDate = request.getParameter("check_in_date");
    String outDate = request.getParameter("check_out_date");
    if (tripIdParam == null || hotelIDParam == null || inDate==null || outDate==null ) {
        response.sendRedirect("view_trips.jsp");
        return;
    }

    int tripId = Integer.parseInt(tripIdParam);
    int hotelID = Integer.parseInt(hotelIDParam);


    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // Get the price from the listing
        pstmt = con.prepareStatement("SELECT price_per_night FROM Hotel_Listing WHERE hotelID = ?");
        pstmt.setInt(1, hotelID);
        rs = pstmt.executeQuery();

        double price = 0;
        if (rs.next()) {
            price = rs.getDouble("price_per_night");
        }
        rs.close();
        pstmt.close();

        // Get next sequence number (MAX is null when trip has no rows yet)
        pstmt = con.prepareStatement(
            "SELECT MAX(trip_hotel_sequence_num) AS max_seq FROM Trip_Hotels WHERE tripID = ?"
        );
        pstmt.setInt(1, tripId);
        rs = pstmt.executeQuery();

        int nextSeq = 1;
        if (rs.next()) {
            Object maxObj = rs.getObject("max_seq");
            if (maxObj != null) {
                nextSeq = ((Number) maxObj).intValue() + 1;
            }
        }
        rs.close();
        pstmt.close();

        // Insert into Trip_Hotel
        pstmt = con.prepareStatement(
            "INSERT INTO Trip_Hotels (trip_hotel_sequence_num, tripID, hotelID, check_in_date, check_out_date, booked_price_per_night,total_cost, booking_status) " +
            "VALUES (?, ?, ?, ?, ?,?, ?* GREATEST(1,DATEDIFF(?,?)),'planned')"
        );
        pstmt.setInt(1, nextSeq);
        pstmt.setInt(2, tripId);
        pstmt.setInt(3, hotelID);
        pstmt.setString(4, inDate);
        pstmt.setString(5, outDate);
        pstmt.setDouble(6,price); //price -> booked_price_per_night
        pstmt.setDouble(7,price); //price -> total_cost 
        pstmt.setString(8, outDate); // for total_cost calculation
        pstmt.setString(9, inDate); // for total_cost calculation
        pstmt.executeUpdate(); 
        pstmt.close();
        con.close();

        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&success=Hotel+added+to+trip.");

    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Could+not+add+hotel.");
    }
%>