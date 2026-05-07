<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>
<%
    Integer userID = (Integer) session.getAttribute("userID");
    if (userID == null || !"company".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String transportName     = request.getParameter("transport_name");
    String transportType     = request.getParameter("transport_type");
    String departureLocation = request.getParameter("departure_location");
    String arrivalDest       = request.getParameter("arrival_destination");
    String departureTime     = request.getParameter("departure_time");
    String arrivalTime       = request.getParameter("arrival_time");
    String costStr           = request.getParameter("base_cost");

    if (transportName == null || transportName.trim().isEmpty() ||
        transportType == null  || transportType.trim().isEmpty() ||
        departureLocation == null || departureLocation.trim().isEmpty() ||
        arrivalDest == null    || arrivalDest.trim().isEmpty() ||
        departureTime == null  || departureTime.trim().isEmpty() ||
        arrivalTime == null    || arrivalTime.trim().isEmpty() ||
        costStr == null        || costStr.trim().isEmpty()) {
        response.sendRedirect("company_dashboard.jsp?error=Please+fill+in+all+required+fields.");
        return;
    }

    double cost = 0;
    try { cost = Double.parseDouble(costStr); } catch (Exception e) {
        response.sendRedirect("company_dashboard.jsp?error=Invalid+cost.");
        return;
    }

    Connection con = null;
    PreparedStatement pstmt = null;
    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        pstmt = con.prepareStatement(
            "INSERT INTO Transport_Listing (company_userID, transport_type, transport_name, departure_location, arrival_destination, departure_time, arrival_time, base_cost, availability, listing_status, last_fetched) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'available', 'active', NOW())",
            Statement.RETURN_GENERATED_KEYS
        );
        pstmt.setInt(1, userID);
        pstmt.setString(2, transportType);
        pstmt.setString(3, transportName.trim());
        pstmt.setString(4, departureLocation.trim().toUpperCase());
        pstmt.setString(5, arrivalDest.trim().toUpperCase());
        pstmt.setString(6, departureTime.replace("T", " "));
        pstmt.setString(7, arrivalTime.replace("T", " "));
        pstmt.setDouble(8, cost);
        pstmt.executeUpdate();

        ResultSet keys = pstmt.getGeneratedKeys();
        int newTransportID = 0;
        if (keys.next()) newTransportID = keys.getInt(1);
        keys.close();
        pstmt.close();

        pstmt = con.prepareStatement("INSERT INTO Posts_Transportation (company_userID, transportID) VALUES (?, ?)");
        pstmt.setInt(1, userID);
        pstmt.setInt(2, newTransportID);
        pstmt.executeUpdate();
        pstmt.close();

        con.close();
        response.sendRedirect("company_dashboard.jsp?success=Transportation+listing+posted.");
    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) try { con.close(); } catch (Exception ex) {}
        response.sendRedirect("company_dashboard.jsp?error=Failed+to+post+listing.");
    }
%>
