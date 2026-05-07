<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="WEB-INF/db_config.jsp" %>

<%
    String username = (String) session.getAttribute("username");
    Integer userID  = (Integer) session.getAttribute("userID");

    if (username == null) {
        response.sendRedirect("login.jsp");
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
    ResultSet rs = null;

    String tripName = "", startLocation = "", destination = "", startDate = "", endDate = "";
    int paymentID = 0;
    double paymentAmount = 0.0;
    String paymentMethod = "", paymentTimestamp = "", paymentStatus = "";

    java.util.ArrayList<java.util.HashMap<String, String>> outboundFlights = new java.util.ArrayList<>();
    java.util.ArrayList<java.util.HashMap<String, String>> returnFlights   = new java.util.ArrayList<>();
    java.util.ArrayList<java.util.HashMap<String, String>> hotels          = new java.util.ArrayList<>();

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        pstmt = con.prepareStatement(
            "SELECT trip_name, start_location, destination, start_date, end_date " +
            "FROM Trip WHERE tripID = ? AND userID = ?"
        );
        pstmt.setInt(1, tripId);
        pstmt.setInt(2, userID);
        rs = pstmt.executeQuery();
        if (!rs.next()) {
            response.sendRedirect("view_trips.jsp");
            return;
        }
        tripName      = rs.getString("trip_name");
        startLocation = rs.getString("start_location");
        destination   = rs.getString("destination");
        startDate     = rs.getString("start_date");
        endDate       = rs.getString("end_date");
        rs.close(); pstmt.close();

        try {
            java.text.SimpleDateFormat inFmt  = new java.text.SimpleDateFormat("yyyy-MM-dd");
            java.text.SimpleDateFormat outFmt = new java.text.SimpleDateFormat("MM/dd/yyyy");
            if (startDate != null && !startDate.isEmpty()) startDate = outFmt.format(inFmt.parse(startDate));
            if (endDate   != null && !endDate.isEmpty())   endDate   = outFmt.format(inFmt.parse(endDate));
        } catch (Exception e) {}

        pstmt = con.prepareStatement(
            "SELECT paymentID, amount, payment_method, payment_status, payment_timestamp " +
            "FROM Payments WHERE tripID = ? AND userID = ? ORDER BY payment_timestamp DESC LIMIT 1"
        );
        pstmt.setInt(1, tripId);
        pstmt.setInt(2, userID);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            paymentID        = rs.getInt("paymentID");
            paymentAmount    = rs.getDouble("amount");
            paymentMethod    = rs.getString("payment_method");
            paymentStatus    = rs.getString("payment_status");
            paymentTimestamp = rs.getString("payment_timestamp");
        }
        rs.close(); pstmt.close();

        pstmt = con.prepareStatement(
            "SELECT tt.direction, tt.price, tl.transport_name, tl.departure_location, " +
            "tl.arrival_destination, tl.departure_time, tl.arrival_time " +
            "FROM Trip_Transportation tt " +
            "JOIN Transport_Listing tl ON tt.transportID = tl.transportID " +
            "WHERE tt.tripID = ? ORDER BY tt.trip_transport_sequence_num"
        );
        pstmt.setInt(1, tripId);
        rs = pstmt.executeQuery();
        while (rs.next()) {
            java.util.HashMap<String, String> t = new java.util.HashMap<>();
            t.put("direction",           rs.getString("direction"));
            t.put("price",               rs.getString("price"));
            t.put("transport_name",      rs.getString("transport_name"));
            t.put("departure_location",  rs.getString("departure_location"));
            t.put("arrival_destination", rs.getString("arrival_destination"));
            t.put("departure_time",      rs.getString("departure_time"));
            t.put("arrival_time",        rs.getString("arrival_time"));
            if ("return".equals(t.get("direction"))) returnFlights.add(t);
            else outboundFlights.add(t);
        }
        rs.close(); pstmt.close();

        pstmt = con.prepareStatement(
            "SELECT th.check_in_date, th.check_out_date, th.booked_price_per_night, th.total_cost, " +
            "hl.hotel_name, hl.location " +
            "FROM Trip_Hotels th " +
            "JOIN Hotel_Listing hl ON th.hotelID = hl.hotelID " +
            "WHERE th.tripID = ? ORDER BY th.trip_hotel_sequence_num"
        );
        pstmt.setInt(1, tripId);
        rs = pstmt.executeQuery();
        while (rs.next()) {
            java.util.HashMap<String, String> h = new java.util.HashMap<>();
            h.put("hotel_name",    rs.getString("hotel_name"));
            h.put("location",      rs.getString("location"));
            h.put("check_in",      rs.getString("check_in_date"));
            h.put("check_out",     rs.getString("check_out_date"));
            h.put("per_night",     rs.getString("booked_price_per_night"));
            h.put("total_cost",    rs.getString("total_cost"));
            hotels.add(h);
        }
        rs.close(); pstmt.close();

    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (con != null) { try { con.close(); } catch (Exception ex) {} }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Travelog — Receipt #<%= paymentID %></title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .receipt {
            background: var(--warm-white);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            width: 100%;
            max-width: 540px;
            padding: 48px 40px;
            box-shadow: 0 4px 24px rgba(0,0,0,0.06);
            position: relative;
        }

        .receipt-header {
            text-align: center;
            padding-bottom: 24px;
            border-bottom: 2px dashed var(--border);
        }

        .receipt-id {
            font-size: 0.72rem;
            font-weight: 600;
            letter-spacing: 1.5px;
            text-transform: uppercase;
            color: var(--text-muted);
            margin-top: 12px;
        }

        .receipt-stamp {
            display: inline-block;
            padding: 4px 14px;
            border-radius: 4px;
            font-size: 0.7rem;
            font-weight: 700;
            letter-spacing: 2px;
            text-transform: uppercase;
            margin-top: 10px;
        }

        .stamp-paid     { background: var(--success-bg); color: var(--success); border: 1.5px solid var(--success); }
        .stamp-refunded { background: var(--danger-bg);  color: var(--danger);  border: 1.5px solid var(--danger); }

        .receipt-section {
            padding: 20px 0;
            border-bottom: 1px dashed var(--border);
        }

        .receipt-section:last-of-type {
            border-bottom: none;
        }

        .receipt-section-label {
            font-size: 0.68rem;
            font-weight: 700;
            letter-spacing: 1.5px;
            text-transform: uppercase;
            color: var(--text-muted);
            margin-bottom: 12px;
        }

        .receipt-row {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 8px;
            gap: 16px;
        }

        .receipt-row-label {
            font-size: 0.88rem;
            color: var(--text-body);
            font-weight: 500;
            flex: 1;
        }

        .receipt-row-sub {
            font-size: 0.76rem;
            color: var(--text-muted);
            margin-top: 2px;
        }

        .receipt-row-price {
            font-size: 0.88rem;
            font-weight: 600;
            color: var(--charcoal);
            white-space: nowrap;
        }

        .receipt-total-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding-top: 20px;
            margin-top: 4px;
            border-top: 2px dashed var(--border);
        }

        .receipt-total-label {
            font-family: 'DM Serif Display', serif;
            font-size: 1.1rem;
            color: var(--charcoal);
        }

        .receipt-total-amount {
            font-family: 'DM Serif Display', serif;
            font-size: 1.4rem;
            color: var(--accent);
        }

        .receipt-meta-row {
            display: flex;
            justify-content: space-between;
            font-size: 0.8rem;
            color: var(--text-muted);
            font-weight: 500;
            margin-bottom: 6px;
        }

        .receipt-meta-row span:last-child {
            color: var(--text-body);
            font-weight: 600;
            text-transform: capitalize;
        }

        @media print {
            .no-print { display: none !important; }
            body { background: white; }
            .page-wrapper { padding: 0; }
            .receipt { box-shadow: none; border: none; max-width: 100%; }
        }
    </style>
</head>
<body>
<div class="page-wrapper">

    <div class="no-print" style="width: 100%; max-width: 540px; display: flex; justify-content: space-between; gap: 12px; margin-bottom: 24px;">
        <a href="trip_details.jsp?tripId=<%= tripId %>" class="btn btn-secondary">Back to Trip</a>
        <button onclick="window.print()" class="btn btn-primary">Print Receipt</button>
    </div>

    <div class="receipt">

        <%-- Header --%>
        <div class="receipt-header">
            <div class="duck-mark large" style="margin: 0 auto 8px;"></div>
            <h1 class="brand-title" style="font-size: 1.8rem;">Travelog<span class="accent-dot">.</span></h1>
            <div class="receipt-id">Receipt #<%= String.format("%06d", paymentID) %></div>
            <div>
                <span class="receipt-stamp <%= "refunded".equals(paymentStatus) ? "stamp-refunded" : "stamp-paid" %>">
                    <%= "refunded".equals(paymentStatus) ? "Refunded" : "Paid" %>
                </span>
            </div>
        </div>

        <%-- Trip info --%>
        <div class="receipt-section">
            <div class="receipt-section-label">Trip</div>
            <div class="receipt-row">
                <div class="receipt-row-label">
                    <%= tripName %>
                    <div class="receipt-row-sub"><%= startLocation %> &rarr; <%= destination %></div>
                    <div class="receipt-row-sub"><%= startDate %> &mdash; <%= endDate %></div>
                </div>
            </div>
        </div>

        <%-- Outbound flights --%>
        <% if (!outboundFlights.isEmpty()) { %>
        <div class="receipt-section">
            <div class="receipt-section-label">Outbound Flight<%= outboundFlights.size() > 1 ? "s" : "" %></div>
            <% for (java.util.HashMap<String, String> t : outboundFlights) { %>
            <div class="receipt-row">
                <div class="receipt-row-label">
                    <%= t.get("transport_name") %>
                    <div class="receipt-row-sub"><%= t.get("departure_location") %> &rarr; <%= t.get("arrival_destination") %></div>
                    <div class="receipt-row-sub"><%= t.get("departure_time") %> &rarr; <%= t.get("arrival_time") %></div>
                </div>
                <div class="receipt-row-price">$<%= String.format("%.2f", Double.parseDouble(t.get("price"))) %></div>
            </div>
            <% } %>
        </div>
        <% } %>

        <%-- Return flights --%>
        <% if (!returnFlights.isEmpty()) { %>
        <div class="receipt-section">
            <div class="receipt-section-label">Return Flight<%= returnFlights.size() > 1 ? "s" : "" %></div>
            <% for (java.util.HashMap<String, String> t : returnFlights) { %>
            <div class="receipt-row">
                <div class="receipt-row-label">
                    <%= t.get("transport_name") %>
                    <div class="receipt-row-sub"><%= t.get("departure_location") %> &rarr; <%= t.get("arrival_destination") %></div>
                    <div class="receipt-row-sub"><%= t.get("departure_time") %> &rarr; <%= t.get("arrival_time") %></div>
                </div>
                <div class="receipt-row-price">$<%= String.format("%.2f", Double.parseDouble(t.get("price"))) %></div>
            </div>
            <% } %>
        </div>
        <% } %>

        <%-- Hotels --%>
        <% if (!hotels.isEmpty()) { %>
        <div class="receipt-section">
            <div class="receipt-section-label">Lodging</div>
            <% for (java.util.HashMap<String, String> h : hotels) { %>
            <div class="receipt-row">
                <div class="receipt-row-label">
                    <%= h.get("hotel_name") %>
                    <div class="receipt-row-sub"><%= h.get("location") %></div>
                    <div class="receipt-row-sub"><%= h.get("check_in") %> &rarr; <%= h.get("check_out") %> &nbsp;&middot;&nbsp; $<%= String.format("%.2f", Double.parseDouble(h.get("per_night"))) %>/night</div>
                </div>
                <div class="receipt-row-price">$<%= String.format("%.2f", Double.parseDouble(h.get("total_cost"))) %></div>
            </div>
            <% } %>
        </div>
        <% } %>

        <%-- Payment info --%>
        <div class="receipt-section">
            <div class="receipt-section-label">Payment</div>
            <div class="receipt-meta-row"><span>Method</span><span><%= paymentMethod %></span></div>
            <div class="receipt-meta-row"><span>Date</span><span><%= paymentTimestamp %></span></div>
            <div class="receipt-meta-row"><span>Status</span><span><%= paymentStatus %></span></div>
        </div>

        <%-- Total --%>
        <div class="receipt-total-row">
            <div class="receipt-total-label">Total</div>
            <div class="receipt-total-amount">$<%= String.format("%.2f", paymentAmount) %></div>
        </div>

    </div>

    <div class="pond-footer no-print">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
</body>
</html>
