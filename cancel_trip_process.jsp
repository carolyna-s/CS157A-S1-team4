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
    if (tripIdParam == null) {
        response.sendRedirect("view_trips.jsp");
        return;
    }

    int tripId = 0;
    try {
        tripId = Integer.parseInt(tripIdParam);
    } catch (NumberFormatException e) {
        response.sendRedirect("view_trips.jsp");
        return;
    }

    Connection con = null;
    PreparedStatement pstmt = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        pstmt = con.prepareStatement(
            "UPDATE Trip SET status = 'cancelled' WHERE tripID = ? AND userID = ? AND status != 'cancelled'"
        );
        pstmt.setInt(1, tripId);
        pstmt.setInt(2, userID);

        int rowsAffected = pstmt.executeUpdate();
        pstmt.close();
        con.close();

        if (rowsAffected > 0) {
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&success=Trip+cancelled+successfully.");
        } else {
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Could+not+cancel+trip.");
        }
    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Database+error.");
    }
%>