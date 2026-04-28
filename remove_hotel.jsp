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
    String seqParam = request.getParameter("seq");
    String hotelIDParam = request.getParameter("hotelID");

    if (tripIdParam == null || seqParam == null || hotelIDParam == null) {
        response.sendRedirect("view_trips.jsp");
        return;
    }

    int tripId = Integer.parseInt(tripIdParam);
    int seq = Integer.parseInt(seqParam);
    int hotelID = Integer.parseInt(hotelIDParam);

    Connection con = null;
    PreparedStatement pstmt = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // Verify the trip belongs to this user before deleting
        pstmt = con.prepareStatement(
            "DELETE th FROM Trip_Hotels th " +
            "JOIN Trip t ON th.tripID = t.tripID " +
            "WHERE th.trip_hotel_sequence_num = ? AND th.tripID = ? AND th.hotelID = ? AND t.userID = ? "
        );
        pstmt.setInt(1, seq);
        pstmt.setInt(2, tripId);
        pstmt.setInt(3, hotelID);
        pstmt.setInt(4, userID);
        pstmt.executeUpdate();
        pstmt.close();
        con.close();

        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&success=Hotel+removed.");

    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Could+not+remove+hotel.");
    }
%>