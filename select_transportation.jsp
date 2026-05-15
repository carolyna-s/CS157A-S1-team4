<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>

<%
    // be signed in to attach transport to a trip
    Integer userID = (Integer) session.getAttribute("userID");

    if (userID == null) {
        response.sendRedirect("login.jsp?error=Invalid+Session.+Please+login+again.");
        return;
    }

    // form fields come from the Select button in browse_transportation.jsp
    String tripIdParam = request.getParameter("tripId");
    String transportIDParam = request.getParameter("transportID");
    String direction = request.getParameter("direction"); // "outbound" or "return"

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

        // grab the listed price so we can lock it in (in case the listing price changes later, the user gets the price they saw at booking)
        pstmt = con.prepareStatement("SELECT base_cost FROM Transport_Listing WHERE transportID = ?");
        pstmt.setInt(1, transportID);
        rs = pstmt.executeQuery();

        double price = 0;
        if (rs.next()) {
            price = rs.getDouble("base_cost");
        }
        rs.close();
        pstmt.close();

        // picking a new transport for the same direction should overwrite the old one
        pstmt = con.prepareStatement(
            "DELETE FROM Trip_Transportation WHERE tripID = ? AND direction = ? AND booking_status = 'planned'"
        );
        pstmt.setInt(1, tripId);
        pstmt.setString(2, direction);
        pstmt.executeUpdate();
        pstmt.close();

        // figure out the next sequence num for this trip's transport list
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

        // finally insert the row, starts as planned until they actually pay
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

        pstmt = con.prepareStatement("INSERT IGNORE INTO Includes_Transportation (tripID, transportID) VALUES (?, ?)");
        pstmt.setInt(1, tripId);
        pstmt.setInt(2, transportID);
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