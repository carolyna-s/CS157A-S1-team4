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
    String seqParam = request.getParameter("seq");
    String transportIDParam = request.getParameter("transportID");

    if (tripIdParam == null || seqParam == null || transportIDParam == null) {
        response.sendRedirect("view_trips.jsp");
        return;
    }

    int tripId = Integer.parseInt(tripIdParam);
    int seq = Integer.parseInt(seqParam);
    int transportID = Integer.parseInt(transportIDParam);

    Connection con = null;
    PreparedStatement pstmt = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // Verify the trip belongs to this user before deleting
        pstmt = con.prepareStatement(
            "DELETE tt FROM Trip_Transportation tt " +
            "JOIN Trip t ON tt.tripID = t.tripID " +
            "WHERE tt.trip_transport_sequence_num = ? AND tt.tripID = ? AND tt.transportID = ? AND t.userID = ?"
        );
        pstmt.setInt(1, seq);
        pstmt.setInt(2, tripId);
        pstmt.setInt(3, transportID);
        pstmt.setInt(4, userID);
        pstmt.executeUpdate();
        pstmt.close();
        con.close();

        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&success=Transportation+removed.");

    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Could+not+remove+transportation.");
    }
%>