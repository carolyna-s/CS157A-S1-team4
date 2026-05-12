<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="WEB-INF/db_config.jsp" %>
<%
    String username = (String) session.getAttribute("username");
    Integer userID = (Integer) session.getAttribute("userID");

    if (username == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String tripIdParam = request.getParameter("tripId");
    if (tripIdParam == null) {
        response.sendRedirect("trip_details.jsp"); // maybe error occured message
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

    //these get filled from the try block
    String tripName = "";
    String startLocation = "";
    String destination = "";
    String startDate = "";
    String endDate = "";
    String status = ""; 

    try 
    {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        pstmt = con.prepareStatement(
            "SELECT trip_name, start_location, destination, start_date, end_date, status " +
            " FROM Trip WHERE tripID = ? AND userID = ? "
        );
        pstmt.setInt(1, tripId);
        pstmt.setInt(2, userID);
        rs=pstmt.executeQuery();


        if (rs.next()) {
            tripName = rs.getString("trip_name");
            startLocation = rs.getString("start_location");
            destination = rs.getString("destination");
            startDate = rs.getString("start_date");
            endDate = rs.getString("end_date");
            status = rs.getString("status");
            
            try {
                java.text.SimpleDateFormat inFormat = new java.text.SimpleDateFormat("yyyy-MM-dd");
                java.text.SimpleDateFormat outFormat = new java.text.SimpleDateFormat("MM/dd/yyyy");
                if (startDate != null && !startDate.isEmpty()) startDate = outFormat.format(inFormat.parse(startDate));
                if (endDate != null && !endDate.isEmpty()) endDate = outFormat.format(inFormat.parse(endDate));
            } catch (Exception e) {}
        } else {
            response.sendRedirect("view_trips.jsp");
            return;
        }

       rs.close();
        pstmt.close();
        //keep conn open to get transport + hotel infos
    }
   catch (Exception e) {
        e.printStackTrace();
        out.println("Database connection error: " + e.getMessage());
    }
    if (status == "planned"){ status = "booked";}
    String statusClass = status.toLowerCase();

     java.util.ArrayList<java.util.HashMap<String, String>> selectedTransport = new java.util.ArrayList<>();
    try {
        if (con == null || con.isClosed()) {
            Class.forName(DB_DRIVER);
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        }
        pstmt = con.prepareStatement(
            "SELECT tt.*, tl.transport_name, tl.departure_location, tl.arrival_destination, " +
            "tl.departure_time, tl.arrival_time FROM Trip_Transportation tt " +
            "JOIN Transport_Listing tl ON tt.transportID = tl.transportID " +
            "WHERE tt.tripID = ? ORDER BY tt.trip_transport_sequence_num"
        );
        pstmt.setInt(1, tripId);
        rs = pstmt.executeQuery();
        while (rs.next()) {
            java.util.HashMap<String, String> t = new java.util.HashMap<>();
            t.put("seq", String.valueOf(rs.getInt("trip_transport_sequence_num")));
            t.put("transportID", String.valueOf(rs.getInt("transportID")));
            t.put("transport_name", rs.getString("transport_name"));
            t.put("departure_location", rs.getString("departure_location"));
            t.put("arrival_destination", rs.getString("arrival_destination"));
            t.put("departure_time", rs.getString("departure_time"));
            t.put("arrival_time", rs.getString("arrival_time"));
            t.put("price", rs.getString("price"));
            t.put("direction", rs.getString("direction"));
            t.put("booking_status", rs.getString("booking_status"));
            selectedTransport.add(t);
        }
        rs.close();
        pstmt.close();
    } 
    catch (Exception e) {
        e.printStackTrace();
    } 

     java.util.ArrayList<java.util.HashMap<String, String>> selectedHotels = new java.util.ArrayList<>();
    try{
        if (con == null || con.isClosed()){
            Class.forName(DB_DRIVER);
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        }
        pstmt = con.prepareStatement(
            "SELECT th.*, hl.hotel_name, hl.location, hl.thumbnail_url " +
            "FROM Trip_Hotels th " +
            "JOIN Hotel_Listing hl ON th.hotelID = hl.hotelID " +
            "WHERE th.tripID = ? ORDER BY th.trip_hotel_sequence_num " 
        );
        pstmt.setInt(1,tripId);
        rs=pstmt.executeQuery();
        while(rs.next()){
           java.util.HashMap<String, String> h = new java.util.HashMap<>();
            h.put("seq", String.valueOf(rs.getInt("trip_hotel_sequence_num")));
            h.put("hotelID", String.valueOf(rs.getInt("hotelID")));
            h.put("hotel_name", rs.getString("hotel_name"));
            h.put("location", rs.getString("location"));
            
            String checkIn = rs.getString("check_in_date");
            String checkOut = rs.getString("check_out_date");
            try {
                java.text.SimpleDateFormat inFormat = new java.text.SimpleDateFormat("yyyy-MM-dd");
                java.text.SimpleDateFormat outFormat = new java.text.SimpleDateFormat("MM/dd/yyyy");
                if (checkIn != null && !checkIn.isEmpty()) checkIn = outFormat.format(inFormat.parse(checkIn));
                if (checkOut != null && !checkOut.isEmpty()) checkOut = outFormat.format(inFormat.parse(checkOut));
            } catch (Exception e) {}
            
            h.put("check_in_date", checkIn != null ? checkIn : "");
            h.put("check_out_date", checkOut != null ? checkOut : "");
            
            h.put("price_per_night",rs.getString("booked_price_per_night"));
            h.put("total_cost", rs.getString("total_cost"));
            h.put("booking_status", rs.getString("booking_status"));
            h.put("thumbnail_url", rs.getString("thumbnail_url"));
            selectedHotels.add(h); 
        }
        rs.close();
        pstmt.close();
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
    }


%>


<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Travelog — <%= tripName %></title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">
        <% // loading this earlier
        java.util.ArrayList<java.util.HashMap<String, String>> outboundFlights = new java.util.ArrayList<>();
        java.util.ArrayList<java.util.HashMap<String, String>> returnFlights = new java.util.ArrayList<>();
        double grandTotal = 0.0;
        
        for (java.util.HashMap<String, String> t : selectedTransport) {
            try {
                if (t.get("price") != null) {
                    grandTotal += Double.parseDouble(t.get("price"));
                }
            } catch (NumberFormatException e) {}
            
            if ("return".equals(t.get("direction"))) {
                returnFlights.add(t);
            } else {
                outboundFlights.add(t);
            }
        }
        
        for (java.util.HashMap<String, String> h : selectedHotels) {
            try {
                if (h.get("total_cost") != null) {
                    grandTotal += Double.parseDouble(h.get("total_cost"));
                }
            } catch (NumberFormatException e) {}
        }
    %>
    <div style="width: 100%; max-width: 820px; display: flex; justify-content: flex-end; gap: 12px;">
        <a href="dashboard.jsp" class="btn btn-secondary">Dashboard</a>
    </div>

    <div class="hero">
        <div class="duck-mark hero" style="margin-bottom: -8px;"></div>
        <h1 class="brand-title"> Confirming Your Trip Details <span class="accent-dot"></span></h1>
        <p class="brand-subtitle"><%= tripName %> </p>

        
        <p class="brand-subtitle"><%= startLocation %> &rarr; <%= destination %></p>
        <p class="brand-subtitle"> <%= startDate %> -  <%= endDate %></p>
    </div>



    <div class="card card-wide" style="margin-bottom: 12px;">
             <div class = "trip-name" style="margin-top: 16px;">Selected Flights</div>
            <div class="trips-grid" style="margin-top: 16px;">
                
                <% for (java.util.HashMap<String, String> t : outboundFlights) { %>
                    <div class="trip-card">
                        <div class="trip-icon planned">&#9992;</div>
                        <div class="trip-details">
                            <div class = "trip-name">Outbound Flight</div>
                            <div class="trip-route"><%= t.get("transport_name") %></div>
                            <div class="trip-route"><%= t.get("departure_location") %> &rarr; <%= t.get("arrival_destination") %></div>
                            <div class="trip-route"><%= t.get("departure_time") %> &rarr; <%= t.get("arrival_time") %></div>
                        </div>
                        <div class="trip-meta">
                            <div class="trip-name" style="color: var(--text-body);">$<%= String.format("%.2f", Double.parseDouble(t.get("price"))) %></div>
                            
                        </div>
                    </div>
                <% } %>
            </div>
      
        
            <div class="trips-grid" style="margin-top: 16px;">
                <% for (java.util.HashMap<String, String> t : returnFlights) { %>
                    <div class="trip-card">
                        <div class="trip-icon planned">&#9992;</div>
                        <div class="trip-details">
                            <div class="trip-name">Return Flight</div>
                            <div class="trip-route"><%= t.get("transport_name") %></div>
                            <div class="trip-route"><%= t.get("departure_location") %> &rarr; <%= t.get("arrival_destination") %></div>
                            <div class="trip-route"><%= t.get("departure_time") %> &rarr; <%= t.get("arrival_time") %></div>
                        </div>
                        <div class="trip-meta">
                            <div class="trip-name" style="color: var(--text-body);">$<%= String.format("%.2f", Double.parseDouble(t.get("price"))) %></div>
                           
                            
                        </div>
                    </div>
                <% } %>
            </div>
            <div class = "trip-name" style="margin-top: 16px;">Selected Lodging</div>
            <div class="trips-grid" style="margin-top: 8px;">
                
                <% for (java.util.HashMap<String, String> h : selectedHotels) { %>
                    <div class="trip-card">
                        <% if (h.get("thumbnail_url") != null && !h.get("thumbnail_url").isEmpty()) { %>
                            <div style="width: 48px; height: 48px; border-radius: 8px; overflow: hidden; flex-shrink: 0; display: flex; align-items: center; justify-content: center; background: #f0f0f0;">
                                <img src="<%= h.get("thumbnail_url") %>" alt="Hotel Thumbnail" style="width: 100%; height: 100%; object-fit: cover;">
                            </div>
                        <% } else { %>
                            <div class="trip-icon planned">&#127976;</div>
                        <% } %>
                        <div class="trip-details">
                            <div class="trip-name"><%= h.get("hotel_name") %></div>
                            <div class="trip-route"><%= h.get("location") %></div>
                            <div class="trip-route"><%= h.get("check_in_date") %> &rarr; <%= h.get("check_out_date") %></div>
                        </div>
                        <div class="trip-meta">
                            <div class="trip-name" style="color: var(--text-body);">$<%= String.format("%.2f", Double.parseDouble(h.get("total_cost"))) %></div>
                            <div class="trip-name" style="color: var(--accent); font-size:0.85rem;">$<%= String.format("%.2f", Double.parseDouble(h.get("price_per_night"))) %>/night</div>
                           
                        </div>
                       
                    </div>
                <% } %>
            </div>
            <div class="trip-name" style="margin-top: 16px;">Pricing</div>
             <div class="trip-route" style="margin-top: 4px; color: var(--text-body);">Includes all selected flights and lodging</div>
            <div class="trips-grid" style = "margin-top: 8px">
                
                    <div class="trip-card">
                        <div class="trip-details">
                            <div class="trip-name" style="font-size: 1.25rem; font-weight: bold; color: var(--accent);">Total Trip Cost: $<%= String.format("%.2f", grandTotal) %></div>
                           
                        </div>
                    </div>

            </div>
        
    </div>




<div class="card card-wide" style="margin-bottom: 24px;">


    <div class="card card-wide" style="margin-bottom: 24px;">
        <h2>Add Payment Details</h2>

        <%
            String success = request.getParameter("success");
            if (success != null) {
        %>
            <div class="alert alert-success" style="margin-top: 16px;"><%= success %></div>
        <%
            }
            String error = request.getParameter("error");
            if (error != null) {
        %>
            <div class="alert alert-error" style="margin-top: 16px;"><%= error %></div>
        <%
            }
        %>

        <form action="payment_status_process.jsp" method="POST" style="margin-top: 18px;">
            <input type="hidden" name="tripId" value="<%= tripId %>">
            <input type="hidden" name="grandTotal" value="<%= grandTotal %>">

            <div class="form-group">
                <label>Payment Method</label>
                <select name="payment_method" required style="width:100%; padding:13px 16px; border:1px solid var(--border); border-radius:var(--radius); font-family:'DM Sans',sans-serif; font-size:0.95rem; color:var(--charcoal); background:var(--cream); outline:none;">
                    <option value="visa">Visa</option>
                    <option value="mastercard">Mastercard</option>
                    <option value="amex">Amex</option>
                    <option value="paypal">PayPal</option>
                </select>
            </div>
            <div class="form-group">
                <label>Cardholder Name</label>
                <input type="text" name="trip_name" placeholder="Cardholder First and Last Name" required>
            </div>
            <div class="form-group">
    <label>Cardholder Number</label>
            <input type="text" name="card_number" id="card_number" placeholder="0000 0000 0000 0000" maxlength="19" inputmode="numeric" required >
        </div>

        <script>
        const cardInput = document.getElementById('card_number');

        cardInput.addEventListener('input', (e) => {
            // remove nonnumerics
            let value = e.target.value.replace(/\D/g, '');
            
            // add spaces in between 4-digit blocks
            let formattedValue = value.match(/.{1,4}/g);
            
            if (formattedValue) {
                e.target.value = formattedValue.join(' ');
            } else {
                e.target.value = '';
            }
        });
        </script>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
            
                <div class="form-group">
                    <label>Expiry</label>
                    <input 
                        type="text" name="exp_date" id="expiry" placeholder="MM/YY"  maxlength="5" inputmode="numeric"  required>
                </div>

                <script>
                const expiryInput = document.getElementById('expiry');

                expiryInput.addEventListener('input', (e) => {
                    let value = e.target.value.replace(/\D/g, ''); 
                    
                    if (value.length > 2) {
                    e.target.value = value.substring(0, 2) + '/' + value.substring(2, 4);
                    } else {
                    e.target.value = value;
                    }
                });

                //
                expiryInput.addEventListener('keydown', (e) => {
                    if (e.key === 'Backspace' && expiryInput.value.length === 3) {
                    expiryInput.value = expiryInput.value.slice(0, 2);
                    }
                });
                </script>
                
                <div class="form-group">
                    <label>CVV</label>
                <input type="password" name="cvv" maxlength="3" required>
                </div>

            </div>
    </div>

    <div style="display: flex; justify-content: center; align-items: center; gap: 20px; padding: 20px; width: 100%;">
            <button type="submit" class="btn btn-primary">Confirm & Pay for Booking</button>
        <a href="view_trips.jsp" class="btn btn-secondary">Go Back to Trips</a>
    </div>
        </form>
</div>
    </div>
     



    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
</body>
</html>

