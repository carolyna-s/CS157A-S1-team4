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
    String tripName = request.getParameter("trip_name");
    String startLocation = request.getParameter("start_location");
    String destination = request.getParameter("destination");
    String startDate = request.getParameter("start_date");
    String endDate = request.getParameter("end_date");

    int tripId = 0;
    try {
        tripId = Integer.parseInt(tripIdParam);
    } catch (NumberFormatException e) {
        response.sendRedirect("view_trips.jsp");
        return;
    }

    if (tripName == null || tripName.trim().isEmpty()) {
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Please+enter+a+trip+name.");
        return;
    }
    if (startLocation == null || startLocation.trim().isEmpty() || destination == null || destination.trim().isEmpty()) {
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Please+check+and+submit+location+fields.");
        return;
    }
    if (startDate == null || startDate.trim().isEmpty() || endDate == null || endDate.trim().isEmpty()) {
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Please+check+and+submit+date+fields.");
        return;
    }

    try {
        java.sql.Date sqlStartDate = java.sql.Date.valueOf(startDate);
        java.sql.Date sqlEndDate = java.sql.Date.valueOf(endDate);
        if (sqlStartDate.after(sqlEndDate)) {
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Start+date+must+be+before+end+date.");
            return;
        }
    } catch (IllegalArgumentException e) {
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Invalid+date+format.");
        return;
    }

    Connection con = null;
    PreparedStatement pstmt = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        pstmt = con.prepareStatement(
            "UPDATE Trip SET trip_name = ?, start_location = ?, destination = ?, start_date = ?, end_date = ? " +
            "WHERE tripID = ? AND userID = ?"
        );
        pstmt.setString(1, tripName.trim());
        pstmt.setString(2, startLocation.trim());
        pstmt.setString(3, destination.trim());
        pstmt.setDate(4, java.sql.Date.valueOf(startDate));
        pstmt.setDate(5, java.sql.Date.valueOf(endDate));
        pstmt.setInt(6, tripId);
        pstmt.setInt(7, userID);

        int rowsAffected = pstmt.executeUpdate();
        pstmt.close();
        con.close();

        if (rowsAffected > 0) {
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&success=Trip+updated+successfully.");
        } else {
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Could+not+update+trip.");
        }
    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Database+error.");
    }
%>