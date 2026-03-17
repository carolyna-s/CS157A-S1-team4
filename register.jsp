<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Travelog — Register</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div class="card">
        <div class="card-header">
            <div class="duck-mark large"></div>
            <h1 class="brand-title" style="font-size: 2rem;">Get started<span class="accent-dot">.</span></h1>
            <p class="brand-subtitle">Create your Travelog account</p>
        </div>

        <%
            String error = request.getParameter("error");
            if (error != null) {
        %>
            <div class="alert alert-error"><%= error %></div>
        <%
            }
        %>

        <form action="register_process.jsp" method="POST">

            <div class="form-group">
                <label>Username</label>
                <input type="text" name="username" placeholder="Choose a username" required>
            </div>

            <div class="form-group">
                <label>Email</label>
                <input type="email" name="email" placeholder="you@email.com" required>
            </div>

            <div class="form-group">
                <label>Password</label>
                <input type="password" name="password" placeholder="Minimum 8 characters" required>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                <div class="form-group">
                    <label>First Name</label>
                    <input type="text" name="firstName" placeholder="First" required>
                </div>
                <div class="form-group">
                    <label>Last Name</label>
                    <input type="text" name="lastName" placeholder="Last" required>
                </div>
            </div>

            <div class="form-group">
                <label>Home Location</label>
                <input type="text" name="location" placeholder="City" required>
            </div>

            <button type="submit" class="btn btn-primary btn-full">Create Account</button>

        </form>

        <div class="form-divider">or</div>

        <div class="text-center">
            <a href="login.jsp" class="link">Already have an account? Sign in</a>
        </div>
    </div>

    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
</body>
</html>