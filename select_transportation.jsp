<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>

<%
    Integer userID = (Integer) session.getAttribute("userID");

    if (userID == null) {
        response.sendRedirect("login.jsp?error=Invalid+Session.+Please+login+again.");
        return;
    }

    String tripIdParam = request.getParameter("tripId");
    String transportIDParam = request.getParameter("transportID");
    String direction = request.getParameter("direction");

    if (tripIdParam == null || transportIDParam == null || direction == null) {
        response.sendRedirect("view_trips.jsp");
        return;
    }

    int tripId = Integer.parseInt(tripIdParam);
    int transportID = Integer.parseInt(transportIDParam);

    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // Get the price from the listing
        pstmt = con.prepareStatement("SELECT base_cost FROM Transport_Listing WHERE transportID = ?");
        pstmt.setInt(1, transportID);
        rs = pstmt.executeQuery();

        double price = 0;
        if (rs.next()) {
            price = rs.getDouble("base_cost");
        }
        rs.close();
        pstmt.close();

        // Get next sequence number (MAX is null when trip has no rows yet)
        pstmt = con.prepareStatement(
            "SELECT MAX(trip_transport_sequence_num) AS max_seq FROM Trip_Transportation WHERE tripID = ?"
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

        // Insert into Trip_Transportation
        pstmt = con.prepareStatement(
            "INSERT INTO Trip_Transportation (trip_transport_sequence_num, tripID, transportID, direction, price, booking_status) " +
            "VALUES (?, ?, ?, ?, ?, 'planned')"
        );
        pstmt.setInt(1, nextSeq);
        pstmt.setInt(2, tripId);
        pstmt.setInt(3, transportID);
        pstmt.setString(4, direction);
        pstmt.setDouble(5, price);
        pstmt.executeUpdate();
        pstmt.close();
        con.close();

        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&success=Transportation+added+to+trip.");

    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Could+not+add+transportation.");
    }
%>