<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>

<%
    Integer userID = (Integer) session.getAttribute("userID");
    
    if (userID == null) {
        response.sendRedirect("login.jsp?error=Invalid+Session.+Please+login+again.");
        return;
    }

    String trip_name = request.getParameter("trip_name");
    String start_location = request.getParameter("start_location");
    String destination = request.getParameter("destination");
    String start_date = request.getParameter("start_date");
    String end_date = request.getParameter("end_date");
    
    if (trip_name == null || trip_name.trim().isEmpty()) 
    {
        response.sendRedirect("create_trip.jsp?error=Please+enter+trip+name.");
        return;
    }
    if (start_location == null || start_location.trim().isEmpty() || destination == null || destination.trim().isEmpty()) 
    {
        response.sendRedirect("create_trip.jsp?error=Please+check+and+submit+location+fields.");
        return;
    }
    if (start_date == null || start_date.trim().isEmpty() || end_date == null || end_date.trim().isEmpty()) 
    {
        response.sendRedirect("create_trip.jsp?error=Please+check+and+submit+date+fields.");
        return;
    }
    try {
        java.sql.Date sqlStartDate = java.sql.Date.valueOf(start_date);
        java.sql.Date sqlEndDate = java.sql.Date.valueOf(end_date);
        if (sqlStartDate.after(sqlEndDate)) {
            response.sendRedirect("create_trip.jsp?error=Start+date+must+be+before+end+date.");
            return;
        }
    } catch (IllegalArgumentException e) {
        response.sendRedirect("create_trip.jsp?error=Invalid+date+format.");
        return;
    }

    Connection con = null;
    PreparedStatement pstmt = null;
    try{
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // create trip using the info
        pstmt = con.prepareStatement(
            "INSERT INTO Trip (userID, trip_name, start_location, destination, start_date, end_date, status) VALUES (?, ?, ?, ?, ?, ?, 'planned')",
            Statement.RETURN_GENERATED_KEYS
        );
        
        pstmt.setInt(1,userID);
        pstmt.setString(2,trip_name.trim());
        pstmt.setString(3,start_location.trim());
        pstmt.setString(4,destination.trim());
        pstmt.setDate(5,java.sql.Date.valueOf(start_date));
        pstmt.setDate(6,java.sql.Date.valueOf(end_date));


        pstmt.executeUpdate();
        ResultSet keys = pstmt.getGeneratedKeys();
        int newTripID = 0;
        if (keys.next()) {
            newTripID = keys.getInt(1);
        }
        keys.close();

        if (newTripID > 0)
        {
            pstmt.close();
            con.close();

            response.sendRedirect("trip_details.jsp?tripId=" + newTripID);
        } 
        else 
        {
            pstmt.close();
            con.close();

            response.sendRedirect("dashboard.jsp?error=Could+not+save+trip.");
        }
    }
        catch (Exception e) { 
        e.printStackTrace(); 
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("dashboard.jsp?error=Database+error.");
    }
%>