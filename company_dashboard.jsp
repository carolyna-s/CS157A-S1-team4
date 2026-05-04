<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String username      = (String) session.getAttribute("username");
    String companyName   = (String) session.getAttribute("companyName");
    String approvalStatus = (String) session.getAttribute("approvalStatus");

    if (username == null || !"company".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp");
        return;
    }
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

    <div style="width:100%; max-width:820px; display:flex; justify-content:flex-end; margin-bottom:-32px;">
        <a href="logout.jsp" class="btn btn-secondary">Logout</a>
    </div>

    <div class="hero">
        <div class="duck-mark hero" style="margin-bottom:-8px;"></div>
        <h1 class="brand-title">Travelog<span class="accent-dot">.</span></h1>
        <p class="brand-subtitle">Company Portal — <%= companyName %></p>
    </div>

    <div class="card card-wide">
        <% if ("pending".equals(approvalStatus)) { %>
            <h2>Awaiting Approval</h2>
            <p style="color:var(--text-muted); font-weight:500; margin-top:12px;">
                Your company account is pending admin approval. You will be notified once reviewed.
            </p>
        <% } else if ("approved".equals(approvalStatus)) { %>
            <h2>Account Approved</h2>
            <p style="color:var(--text-muted); font-weight:500; margin-top:12px;">
                Your company account has been approved.
            </p>
        <% } else if ("rejected".equals(approvalStatus)) { %>
            <h2>Application Rejected</h2>
            <p style="color:#c62828; font-weight:500; margin-top:12px;">
                Your company application was rejected. Please contact support.
            </p>
        <% } %>
    </div>

    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
</body>
</html>
