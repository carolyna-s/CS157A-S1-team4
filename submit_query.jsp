<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // logged in
    // + works for both traveler + company accounts
    String username = (String) session.getAttribute("username");
    Integer userID  = (Integer) session.getAttribute("userID");
    if (username == null || userID == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    // success/error banners come back from submit_query_process through redirect
    String error   = request.getParameter("error");
    String success = request.getParameter("success");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Submit Support Query | Travelog</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div style="width:100%; max-width:820px; display:flex; justify-content:flex-end; gap:12px; margin-bottom:-32px;">
        <a href="dashboard.jsp" class="btn btn-secondary">Dashboard</a>
    </div>

    <div class="hero">
        <div class="duck-mark hero" style="margin-bottom:-8px;"></div>
        <h1 class="brand-title">Support<span class="accent-dot">.</span></h1>
        <p class="brand-subtitle">Submit a question or issue to the Travelog team.</p>
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

    <div class="card card-wide">
        <h2>New Query</h2>
        <form action="submit_query_process.jsp" method="POST" style="margin-top:18px;">
            <div class="form-group">
                <label>Subject</label>
                <input type="text" name="subject" maxlength="200" placeholder="Short summary" required>
            </div>
            <div class="form-group">
                <label>Message</label>
                <textarea name="message_body" rows="6" placeholder="Describe your question or issue..."
                    style="width:100%; padding:10px; border-radius:8px; border:1px solid #ccc; font-family:inherit; resize:vertical;" required></textarea>
            </div>
            <button type="submit" class="btn btn-primary btn-full">Submit Query</button>
        </form>
    </div>

    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
</body>
</html>
