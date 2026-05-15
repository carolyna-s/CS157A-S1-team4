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
    ResultSet rs = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        pstmt = con.prepareStatement(
            "SELECT tt.booking_status, tt.price FROM Trip_Transportation tt " +
            "JOIN Trip t ON tt.tripID = t.tripID " +
            "WHERE tt.trip_transport_sequence_num = ? AND tt.tripID = ? AND tt.transportID = ? AND t.userID = ?"
        );
        pstmt.setInt(1, seq);
        pstmt.setInt(2, tripId);
        pstmt.setInt(3, transportID);
        pstmt.setInt(4, userID);
        rs = pstmt.executeQuery();
        if (!rs.next()) {
            rs.close(); pstmt.close(); con.close();
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Transportation+not+found.");
            return;
        }
        String bookingStatus = rs.getString("booking_status");
        double itemCost      = rs.getDouble("price");
        rs.close();
        pstmt.close();

        if ("booked".equals(bookingStatus)) {
            pstmt = con.prepareStatement(
                "UPDATE Trip_Transportation SET booking_status = 'refunded' " +
                "WHERE trip_transport_sequence_num = ? AND tripID = ? AND transportID = ?"
            );
            pstmt.setInt(1, seq);
            pstmt.setInt(2, tripId);
            pstmt.setInt(3, transportID);
            pstmt.executeUpdate();
            pstmt.close();

            pstmt = con.prepareStatement(
                "SELECT paymentID FROM Payments WHERE tripID = ? AND payment_status IN ('paid','refunded') " +
                "ORDER BY payment_timestamp DESC LIMIT 1"
            );
            pstmt.setInt(1, tripId);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                int paymentID = rs.getInt("paymentID");
                rs.close();
                pstmt.close();

                pstmt = con.prepareStatement(
                    "INSERT INTO Refunds (paymentID, refund_amount, refund_reason, refund_timestamp) " +
                    "VALUES (?, ?, 'Transportation cancelled by user', CURRENT_TIMESTAMP)",
                    Statement.RETURN_GENERATED_KEYS
                );
                pstmt.setInt(1, paymentID);
                pstmt.setDouble(2, itemCost);
                pstmt.executeUpdate();
                ResultSet keys = pstmt.getGeneratedKeys();
                int refundID = 0;
                if (keys.next()) refundID = keys.getInt(1);
                keys.close();
                pstmt.close();

                pstmt = con.prepareStatement("INSERT INTO Receives_Refund (paymentID, refundID) VALUES (?, ?)");
                pstmt.setInt(1, paymentID);
                pstmt.setInt(2, refundID);
                pstmt.executeUpdate();
                pstmt.close();
            } else {
                rs.close();
                pstmt.close();
            }
            con.close();
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&success=Transportation+cancelled+and+$" + String.format("%.2f", itemCost) + "+refunded.");
        } else {
            pstmt = con.prepareStatement(
                "DELETE FROM Trip_Transportation WHERE trip_transport_sequence_num = ? AND tripID = ? AND transportID = ?"
            );
            pstmt.setInt(1, seq);
            pstmt.setInt(2, tripId);
            pstmt.setInt(3, transportID);
            pstmt.executeUpdate();
            pstmt.close();
            con.close();
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&success=Transportation+removed.");
        }

    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Could+not+remove+transportation.");
    }
%>
