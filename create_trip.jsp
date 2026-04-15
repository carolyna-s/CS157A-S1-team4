<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Travelog — Create Trip</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="page-wrapper">

    <div class="card">
        <div class="card-header">
            <div class="duck-mark large"></div>
            <h1 class="brand-title" style="font-size: 2rem;">Create Your Trip<span class="accent-dot">.</span></h1>
        </div>

        <%
            String error = request.getParameter("error");
            if (error != null) {
        %>
            <div class="alert alert-error"><%= error %></div>
        <%
            }
        %>

        <form action="create_trip_process.jsp" method="POST">

            <div class="form-group">
                <label>Trip Name</label>
                <input type="text" name="trip_name" placeholder="Enter Trip Name" required>
            </div>
           
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                <div class="form-group">
                    <label>Current Location</label>
                    <input type="text" name="start_location" placeholder="Current Location" required>
                </div>

                <div class="form-group">
                    <label>Destination</label>
                    <input type="text" name="destination" placeholder="Destination" required>
                </div>
            </div>


            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                <div class="form-group">
                    <label>Start Date</label>
                    <input type="date" name="start_date" placeholder="MM/DD/YYYY" required>
                </div>

                <div class="form-group">
                    <label>End Date</label>
                    <input type="date" name="end_date" placeholder="MM/DD/YYYY" required>
                </div>
            </div>


            <button type="submit" class="btn btn-primary btn-full">Create Trip</button>

        </form>

        <div class="form-divider">or</div>

        <div class="text-center">
            <a href="dashboard.jsp" class="link">Go to Travelog Dashboard</a>
        </div>
    </div>

    <div class="pond-footer">
        <p>Travelog &copy; 2026 — Team 4</p>
    </div>

</div>
</body>
</html>