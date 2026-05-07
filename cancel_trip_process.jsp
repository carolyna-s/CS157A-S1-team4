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

        // cancel the trip
        pstmt = con.prepareStatement(
            "UPDATE Trip SET status = 'cancelled' WHERE tripID = ? AND userID = ? AND status != 'cancelled'"
        );
        pstmt.setInt(1, tripId);
        pstmt.setInt(2, userID);
        int rowsAffected = pstmt.executeUpdate();
        pstmt.close();

        if (rowsAffected == 0) {
            con.close();
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Could+not+cancel+trip.");
            return;
        }

        // cancel all hotels and transportation on this trip
        pstmt = con.prepareStatement("UPDATE Trip_Hotels SET booking_status = 'cancelled' WHERE tripID = ?");
        pstmt.setInt(1, tripId);
        pstmt.executeUpdate();
        pstmt.close();

        pstmt = con.prepareStatement("UPDATE Trip_Transportation SET booking_status = 'cancelled' WHERE tripID = ?");
        pstmt.setInt(1, tripId);
        pstmt.executeUpdate();
        pstmt.close();

        // find the payment for this trip (most recent paid one)
        pstmt = con.prepareStatement(
            "SELECT paymentID, amount FROM Payments WHERE tripID = ? AND payment_status = 'paid' ORDER BY payment_timestamp DESC LIMIT 1"
        );
        pstmt.setInt(1, tripId);
        ResultSet rs = pstmt.executeQuery();

        if (rs.next()) {
            int paymentID = rs.getInt("paymentID");
            double refundAmount = rs.getDouble("amount");
            rs.close();
            pstmt.close();

            // mark payment as refunded
            pstmt = con.prepareStatement("UPDATE Payments SET payment_status = 'refunded' WHERE paymentID = ?");
            pstmt.setInt(1, paymentID);
            pstmt.executeUpdate();
            pstmt.close();

            // insert refund record
            pstmt = con.prepareStatement(
                "INSERT INTO Refunds (paymentID, refund_amount, refund_reason, refund_timestamp) VALUES (?, ?, 'Trip cancelled by user', CURRENT_TIMESTAMP)",
                java.sql.Statement.RETURN_GENERATED_KEYS
            );
            pstmt.setInt(1, paymentID);
            pstmt.setDouble(2, refundAmount);
            pstmt.executeUpdate();

            ResultSet keys = pstmt.getGeneratedKeys();
            int refundID = 0;
            if (keys.next()) refundID = keys.getInt(1);
            keys.close();
            pstmt.close();

            // link refund to payment in Receives_Refund
            pstmt = con.prepareStatement("INSERT INTO Receives_Refund (paymentID, refundID) VALUES (?, ?)");
            pstmt.setInt(1, paymentID);
            pstmt.setInt(2, refundID);
            pstmt.executeUpdate();
            pstmt.close();

            con.close();
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&success=Trip+cancelled+and+full+refund+of+$" + String.format("%.2f", refundAmount) + "+issued.");
        } else {
            // trip was planned (no payment), just cancelled
            rs.close();
            pstmt.close();
            con.close();
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&success=Trip+cancelled+successfully.");
        }
    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Database+error.");
    }
%>