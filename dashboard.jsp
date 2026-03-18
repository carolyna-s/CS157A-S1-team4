<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String username = (String) session.getAttribute("username");

    if (username == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard | Travelog</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div class="hero">
        <div class="duck-mark hero"></div>
        <h1 class="brand-title">Travelog<span class="accent-dot">.</span></h1>
        <p class="brand-subtitle">Welcome back, <%= username %>.</p>

        <div class="hero-actions">
            <a href="create_trip.jsp" class="btn btn-primary">Create Trip</a>
            <a href="logout.jsp" class="btn btn-secondary">Logout</a>
        </div>
    </div>

    <div class="card" style="margin-bottom: 24px;">
        <h2>Your Dashboard</h2>
        <p style="color: var(--text-muted); font-weight: 500; line-height: 1.8; margin-top: 12px;">
            Keep track of your trips, bookings, and travel plans all in one place.
        </p>
    </div>

    <div class="card" style="margin-bottom: 24px;">
        <h2>Quick Actions</h2>
        <div class="hero-actions" style="justify-content: flex-start; margin-top: 18px;">
            <a href="create_trip.jsp" class="btn btn-primary">Start a New Trip</a>
            <a href="view_trips.jsp" class="btn btn-secondary">View Trips</a>
            <a href="account.jsp" class="btn btn-secondary">My Account</a>
        </div>
    </div>

    <div class="card">
        <h2>My Trips</h2>
        <p style="color: var(--text-muted); font-weight: 500; line-height: 1.8; margin-top: 12px; margin-bottom: 20px;">
            You have not created any trips yet.
        </p>
    </div>

    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4 — CS157A</p>
    </div>

</div>
</body>
</html>