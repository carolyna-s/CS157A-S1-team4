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
    ResultSet rs = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // need to know if its planned or booked (booked = refund flow, planned = just delete). join Trip so we also know the trip is actually owned by this user
        pstmt = con.prepareStatement(
            "SELECT th.booking_status, th.total_cost FROM Trip_Hotels th " +
            "JOIN Trip t ON th.tripID = t.tripID " +
            "WHERE th.trip_hotel_sequence_num = ? AND th.tripID = ? AND th.hotelID = ? AND t.userID = ?"
        );
        pstmt.setInt(1, seq);
        pstmt.setInt(2, tripId);
        pstmt.setInt(3, hotelID);
        pstmt.setInt(4, userID);
        rs = pstmt.executeQuery();
        if (!rs.next()) {
            rs.close(); pstmt.close(); con.close();
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Hotel+not+found.");
            return;
        }
        String bookingStatus = rs.getString("booking_status");
        double itemCost      = rs.getDouble("total_cost");
        rs.close();
        pstmt.close();

        if ("booked".equals(bookingStatus)) {
            // booked path so we flip status to refunded (keep history) and log arRefunds row for just this hotel's cost (partial refund)
            pstmt = con.prepareStatement(
                "UPDATE Trip_Hotels SET booking_status = 'refunded' " +
                "WHERE trip_hotel_sequence_num = ? AND tripID = ? AND hotelID = ?"
            );
            pstmt.setInt(1, seq);
            pstmt.setInt(2, tripId);
            pstmt.setInt(3, hotelID);
            pstmt.executeUpdate();
            pstmt.close();

            // get the trip's payment row so we can attach the refund record
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
                // inserting into refunds
                pstmt = con.prepareStatement(
                    "INSERT INTO Refunds (paymentID, refund_amount, refund_reason, refund_timestamp) " +
                    "VALUES (?, ?, 'Hotel cancelled by user', CURRENT_TIMESTAMP)",
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
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&success=Hotel+cancelled+and+$" + String.format("%.2f", itemCost) + "+refunded.");
        } else {
            // we never paid for, then just remove the row (i.e., no refund)
            pstmt = con.prepareStatement(
                "DELETE FROM Trip_Hotels WHERE trip_hotel_sequence_num = ? AND tripID = ? AND hotelID = ?"
            );
            pstmt.setInt(1, seq);
            pstmt.setInt(2, tripId);
            pstmt.setInt(3, hotelID);
            pstmt.executeUpdate();
            pstmt.close();
            con.close();
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&success=Hotel+removed.");
        }

    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Could+not+remove+hotel.");
    }
%>
