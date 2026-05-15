<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>

<%
    // must be signed in
    Integer userID = (Integer) session.getAttribute("userID");

    // login redirection if failed session check
    if (userID == null) {
        response.sendRedirect("login.jsp?error=Invalid+Session.+Please+login+again.");
        return;
    }

    // params come from the cancel form on trip_details.jsp
    String tripIdParam = request.getParameter("tripId");
    String password    = request.getParameter("password");
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

    // spec says cancellation requires password reconfirm: basically no password no cancel
    if (password == null || password.trim().isEmpty()) {
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Password+required+to+cancel+trip.");
        return;
    }

    // hash the typed-in password so we can compare to the stored hash. This is normal security measures, we use SHA-256
    String hashedPassword;
    try {
        MessageDigest digest = MessageDigest.getInstance("SHA-256"); // per this: https://docs.oracle.com/javase/8/docs/api/java/security/MessageDigest.html
        byte[] hashBytes = digest.digest(password.getBytes(StandardCharsets.UTF_8));
        StringBuilder hex = new StringBuilder();
        for (byte b : hashBytes) {
            String h = Integer.toHexString(0xff & b);
            if (h.length() == 1) hex.append('0');
            hex.append(h);
        }
        hashedPassword = hex.toString();
    } catch (Exception e) {
        response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Server+error.");
        return;
    }

    Connection con = null;
    PreparedStatement pstmt = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // password check, if hash doesnt match close the cancel trip process
        pstmt = con.prepareStatement("SELECT userID FROM Users WHERE userID = ? AND password = ?");
        pstmt.setInt(1, userID);
        pstmt.setString(2, hashedPassword);
        ResultSet pwRs = pstmt.executeQuery();
        if (!pwRs.next()) {
            pwRs.close(); pstmt.close(); con.close();
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&error=Incorrect+password.+Cancellation+aborted.");
            return;
        }
        pwRs.close();
        pstmt.close();

        // flip trip status to cancelled using UPDATE + also skip if already cancelled so we dont double-refund
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

        // cascade the cancel down to all child rows on this trip
        pstmt = con.prepareStatement("UPDATE Trip_Hotels SET booking_status = 'cancelled' WHERE tripID = ?");
        pstmt.setInt(1, tripId);
        pstmt.executeUpdate();
        pstmt.close();

        pstmt = con.prepareStatement("UPDATE Trip_Transportation SET booking_status = 'cancelled' WHERE tripID = ?");
        pstmt.setInt(1, tripId);
        pstmt.executeUpdate();
        pstmt.close();

        // refund the recent payment using PaymentID (we look at the most recent one, simple select query)
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

            // flip the payment to refunded so it doesnt show as still paid
            pstmt = con.prepareStatement("UPDATE Payments SET payment_status = 'refunded' WHERE paymentID = ?");
            pstmt.setInt(1, paymentID);
            pstmt.executeUpdate();
            pstmt.close();

            // log the actual refund as a row in refunds so we can check later
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

            // relation table link payment, that we made in the report
            pstmt = con.prepareStatement("INSERT INTO Receives_Refund (paymentID, refundID) VALUES (?, ?)");
            pstmt.setInt(1, paymentID);
            pstmt.setInt(2, refundID);
            pstmt.executeUpdate();
            pstmt.close();

            con.close();
            response.sendRedirect("trip_details.jsp?tripId=" + tripId + "&success=Trip+cancelled+and+full+refund+of+$" + String.format("%.2f", refundAmount) + "+issued.");
        } else {
            // trip was just planned so nothing to refund
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