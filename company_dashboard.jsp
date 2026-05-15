<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>
<%
    String username       = (String) session.getAttribute("username");
    String companyName    = (String) session.getAttribute("companyName");
    String approvalStatus = (String) session.getAttribute("approvalStatus");
    Integer userID        = (Integer) session.getAttribute("userID");

    if (username == null || !"company".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    // double check approval status and business type in case it changed since login
    String businessType = "";
    java.util.ArrayList<java.util.HashMap<String,String>> hotelListings = new java.util.ArrayList<>();
    java.util.ArrayList<java.util.HashMap<String,String>> transportListings = new java.util.ArrayList<>();
    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        pstmt = con.prepareStatement("SELECT approval_status, business_type FROM Company WHERE userID = ?");
        pstmt.setInt(1, userID);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            approvalStatus = rs.getString("approval_status");
            businessType   = rs.getString("business_type");
            session.setAttribute("approvalStatus", approvalStatus);
        }
        rs.close();
        pstmt.close();

        // only show this companys listings if theyve been approved
        if ("approved".equals(approvalStatus)) {
            // hotels owned by this company that arent archived/deleted  yet
            pstmt = con.prepareStatement(
                "SELECT hotelID, hotel_name, location, price_per_night, discount_percent, availability " +
                "FROM Hotel_Listing WHERE company_userID = ? AND listing_status = 'active' ORDER BY hotelID DESC"
            );
            pstmt.setInt(1, userID);
            rs = pstmt.executeQuery();
            while (rs.next()) {
                java.util.HashMap<String,String> h = new java.util.HashMap<>();
                h.put("hotelID", String.valueOf(rs.getInt("hotelID")));
                h.put("hotel_name", rs.getString("hotel_name"));
                h.put("location", rs.getString("location"));
                h.put("price_per_night", rs.getString("price_per_night"));
                h.put("discount_percent", rs.getString("discount_percent"));
                h.put("availability", rs.getString("availability"));
                hotelListings.add(h);
            }
            rs.close();
            pstmt.close();

            // same idea but for transportation listings
            pstmt = con.prepareStatement(
                "SELECT transportID, transport_name, departure_location, arrival_destination, base_cost, discount_percent, availability " +
                "FROM Transport_Listing WHERE company_userID = ? AND listing_status = 'active' ORDER BY transportID DESC"
            );
            pstmt.setInt(1, userID);
            rs = pstmt.executeQuery();
            while (rs.next()) {
                java.util.HashMap<String,String> t = new java.util.HashMap<>();
                t.put("transportID", String.valueOf(rs.getInt("transportID")));
                t.put("transport_name", rs.getString("transport_name"));
                t.put("departure_location", rs.getString("departure_location"));
                t.put("arrival_destination", rs.getString("arrival_destination"));
                t.put("base_cost", rs.getString("base_cost"));
                t.put("discount_percent", rs.getString("discount_percent"));
                t.put("availability", rs.getString("availability"));
                transportListings.add(t);
            }
            rs.close();
            pstmt.close();
        }
        con.close();
    } catch (Exception e) { e.printStackTrace(); }

    String success = request.getParameter("success");
    String error   = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Company Portal | Travelog</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div style="width:100%; max-width:820px; display:flex; justify-content:flex-end; gap:12px; margin-bottom:-32px;">
        <a href="logout.jsp" class="btn btn-secondary">Logout</a>
    </div>

    <div class="hero">
        <div class="duck-mark hero" style="margin-bottom:-8px;"></div>
        <h1 class="brand-title">Travelog<span class="accent-dot">.</span></h1>
        <p class="brand-subtitle">Company Portal — <%= companyName %></p>
    </div>

    <% if (success != null) { %>
        <div class="card card-wide" style="background:#e6f4ea; margin-bottom:16px;">
            <p style="color:#2e7d32; font-weight:600;"><%= success %></p>
        </div>
    <% } %>
    <% if (error != null) { %>
        <div class="card card-wide" style="background:#fdecea; margin-bottom:16px;">
            <p style="color:#c62828; font-weight:600;"><%= error %></p>
        </div>
    <% } %>

    <% if ("pending".equals(approvalStatus)) { %>
        <div class="card card-wide">
            <h2>Awaiting Approval</h2>
            <p style="color:var(--text-muted); font-weight:500; margin-top:12px;">
                Your company account is pending admin approval. You will be notified once reviewed.
            </p>
        </div>

    <% } else if ("rejected".equals(approvalStatus)) { %>
        <div class="card card-wide">
            <h2>Application Rejected</h2>
            <p style="color:#c62828; font-weight:500; margin-top:12px;">
                Your company application was rejected. Please contact support.
            </p>
        </div>

    <% } else if ("approved".equals(approvalStatus)) { %>

        <% if ("hotel".equals(businessType) || "both".equals(businessType)) { %>
        <div class="card card-wide" style="margin-bottom:24px;">
            <h2>Post a Hotel Listing</h2>
            <form action="post_hotel_process.jsp" method="POST" style="margin-top:18px;">
                <div class="form-group">
                    <label>Hotel Name</label>
                    <input type="text" name="hotel_name" placeholder="e.g. Marriott Downtown" required>
                </div>
                <div class="form-group">
                    <label>Location (City)</label>
                    <input type="text" name="location" placeholder="e.g. San Jose" required>
                </div>
                <div class="form-group">
                    <label>Description</label>
                    <textarea name="description" rows="3" placeholder="Brief description..."
                        style="width:100%; padding:10px; border-radius:8px; border:1px solid #ccc; font-family:inherit; resize:vertical;"></textarea>
                </div>
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                    <div class="form-group">
                        <label>Price per Night (USD)</label>
                        <input type="number" name="price_per_night" step="0.01" min="0" placeholder="e.g. 149.99" required>
                    </div>
                    <div class="form-group">
                        <label>Rating (0–5)</label>
                        <input type="number" name="rating" step="0.1" min="0" max="5" placeholder="e.g. 4.2">
                    </div>
                </div>
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                    <div class="form-group">
                        <label>Discount % (0–100)</label>
                        <input type="number" name="discount_percent" step="0.01" min="0" max="100" placeholder="e.g. 10" value="0">
                    </div>
                    <div class="form-group">
                        <label>Availability</label>
                        <select name="availability" style="width:100%; padding:10px; border-radius:8px; border:1px solid #ccc;">
                            <option value="available">Available</option>
                            <option value="unavailable">Unavailable</option>
                        </select>
                    </div>
                </div>
                <button type="submit" class="btn btn-primary">Post Hotel</button>
            </form>
        </div>

        <% if (!hotelListings.isEmpty()) { %>
        <div class="card card-wide" style="margin-bottom:24px;">
            <h2>Your Hotel Listings</h2>
            <table style="width:100%; border-collapse:collapse; margin-top:16px;">
                <thead>
                    <tr style="text-align:left; border-bottom:2px solid #eee;">
                        <th style="padding:8px;">Hotel</th>
                        <th style="padding:8px;">Location</th>
                        <th style="padding:8px;">Price/Night</th>
                        <th style="padding:8px;">Discount</th>
                        <th style="padding:8px;">Available</th>
                        <th style="padding:8px;">Action</th>
                    </tr>
                </thead>
                <tbody>
                <% for (java.util.HashMap<String,String> h : hotelListings) { %>
                    <tr style="border-bottom:1px solid #f0f0f0;">
                        <td style="padding:8px;"><%= h.get("hotel_name") %></td>
                        <td style="padding:8px;"><%= h.get("location") %></td>
                        <td style="padding:8px;">$<%= h.get("price_per_night") %></td>
                        <td style="padding:8px;"><%= h.get("discount_percent") %>%</td>
                        <td style="padding:8px;"><%= h.get("availability") %></td>
                        <td style="padding:8px;">
                            <form action="delete_listing_process.jsp" method="POST"
                                  onsubmit="return confirm('Archive this listing? Existing bookings stay intact.');"
                                  style="display:flex; gap:6px; align-items:center;">
                                <input type="hidden" name="type" value="hotel">
                                <input type="hidden" name="listingID" value="<%= h.get("hotelID") %>">
                                <input type="password" name="password" placeholder="Password" required
                                       style="padding:4px 8px; border:1px solid #ccc; border-radius:6px; font-size:12px; width:110px;">
                                <button type="submit" class="btn btn-danger" style="padding:4px 12px; font-size:12px;">Delete</button>
                            </form>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
        <% } %>
        <% } %>

        <% if ("transportation".equals(businessType) || "both".equals(businessType)) { %>
        <div class="card card-wide" style="margin-bottom:24px;">
            <h2>Post a Transportation Listing</h2>
            <form action="post_transportation_process.jsp" method="POST" style="margin-top:18px;">
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                    <div class="form-group">
                        <label>Transport Name</label>
                        <input type="text" name="transport_name" placeholder="e.g. United Airlines UA 123" required>
                    </div>
                    <div class="form-group">
                        <label>Type</label>
                        <select name="transport_type" required style="width:100%; padding:10px; border-radius:8px; border:1px solid #ccc;">
                            <option value="plane">Plane</option>
                            <option value="bus">Bus</option>
                            <option value="train">Train</option>
                        </select>
                    </div>
                </div>
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                    <div class="form-group">
                        <label>Departure</label>
                        <input type="text" name="departure_location" placeholder="e.g. SJC" required>
                    </div>
                    <div class="form-group">
                        <label>Arrival</label>
                        <input type="text" name="arrival_destination" placeholder="e.g. LAX" required>
                    </div>
                </div>
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                    <div class="form-group">
                        <label>Departure Time</label>
                        <input type="datetime-local" name="departure_time" required>
                    </div>
                    <div class="form-group">
                        <label>Arrival Time</label>
                        <input type="datetime-local" name="arrival_time" required>
                    </div>
                </div>
                <div class="form-group">
                    <label>Base Cost (USD)</label>
                    <input type="number" name="base_cost" step="0.01" min="0" placeholder="e.g. 299.00" required>
                </div>
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                    <div class="form-group">
                        <label>Discount % (0–100)</label>
                        <input type="number" name="discount_percent" step="0.01" min="0" max="100" placeholder="e.g. 10" value="0">
                    </div>
                    <div class="form-group">
                        <label>Availability</label>
                        <select name="availability" style="width:100%; padding:10px; border-radius:8px; border:1px solid #ccc;">
                            <option value="available">Available</option>
                            <option value="unavailable">Unavailable</option>
                        </select>
                    </div>
                </div>
                <button type="submit" class="btn btn-primary">Post Transportation</button>
            </form>
        </div>

        <% if (!transportListings.isEmpty()) { %>
        <div class="card card-wide" style="margin-bottom:24px;">
            <h2>Your Transportation Listings</h2>
            <table style="width:100%; border-collapse:collapse; margin-top:16px;">
                <thead>
                    <tr style="text-align:left; border-bottom:2px solid #eee;">
                        <th style="padding:8px;">Name</th>
                        <th style="padding:8px;">Route</th>
                        <th style="padding:8px;">Base Cost</th>
                        <th style="padding:8px;">Discount</th>
                        <th style="padding:8px;">Available</th>
                        <th style="padding:8px;">Action</th>
                    </tr>
                </thead>
                <tbody>
                <% for (java.util.HashMap<String,String> t : transportListings) { %>
                    <tr style="border-bottom:1px solid #f0f0f0;">
                        <td style="padding:8px;"><%= t.get("transport_name") %></td>
                        <td style="padding:8px;"><%= t.get("departure_location") %> → <%= t.get("arrival_destination") %></td>
                        <td style="padding:8px;">$<%= t.get("base_cost") %></td>
                        <td style="padding:8px;"><%= t.get("discount_percent") %>%</td>
                        <td style="padding:8px;"><%= t.get("availability") %></td>
                        <td style="padding:8px;">
                            <form action="delete_listing_process.jsp" method="POST"
                                  onsubmit="return confirm('Archive this listing? Existing bookings stay intact.');"
                                  style="display:flex; gap:6px; align-items:center;">
                                <input type="hidden" name="type" value="transport">
                                <input type="hidden" name="listingID" value="<%= t.get("transportID") %>">
                                <input type="password" name="password" placeholder="Password" required
                                       style="padding:4px 8px; border:1px solid #ccc; border-radius:6px; font-size:12px; width:110px;">
                                <button type="submit" class="btn btn-danger" style="padding:4px 12px; font-size:12px;">Delete</button>
                            </form>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
        <% } %>
        <% } %>

    <% } %>

    <div style="width:100%; max-width:820px; display:flex; justify-content:center; margin-top:24px;">
        <a href="submit_query.jsp" class="btn btn-secondary">Need help? Submit a Support Query</a>
    </div>

    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
</body>
</html>
