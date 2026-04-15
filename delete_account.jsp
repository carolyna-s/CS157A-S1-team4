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
    <title>Travelog — Delete Account</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div class="card">
        <div class="card-header">
            <div class="duck-mark large"></div>
            <h1 class="brand-title" style="font-size: 2rem;">Delete Account<span class="accent-dot">.</span></h1>
            <p class="brand-subtitle">This action is permanent and cannot be undone.</p>
        </div>

        <%
            String error = request.getParameter("error");
            if (error != null) {
        %>
            <div class="alert alert-error"><%= error %></div>
        <%
            }
        %>

        <div class="alert alert-error" style="margin-bottom: 24px;">
            Warning: Deleting your account will permanently remove all your data, trips, and bookings from Travelog.
        </div>

        <form action="delete_account_process.jsp" method="POST">

            <div class="form-group">
                <label>Confirm Password</label>
                <input type="password" name="password" placeholder="Enter your password to confirm" required>
            </div>

            <button type="submit" class="btn btn-danger btn-full">Delete My Account</button>

        </form>

        <div class="form-divider">or</div>

        <div class="text-center">
            <a href="dashboard.jsp" class="link">Go back to Dashboard</a>
        </div>
    </div>

    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
</body>
</html>