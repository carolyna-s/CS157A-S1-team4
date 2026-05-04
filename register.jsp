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
            <div class="form-group">
                <label>Account Type</label>
                <select name="accountType" id="accountType" onchange="toggleFields()" required
                    style="width:100%; padding: 10px; border-radius: 8px; border: 1px solid #ccc;">
                    <option value="traveler">Traveler</option>
                    <option value="company">Company</option>
                </select>
            </div>     
            
                  

            <!-- Traveler fields -->
            <div id="travelerFields">
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                    <div class="form-group">
                        <label>First Name</label>
                        <input type="text" name="firstName" id="firstName" placeholder="First" required>
                    </div>
                    <div class="form-group">
                        <label>Last Name</label>
                        <input type="text" name="lastName" id="lastName" placeholder="Last" required>
                    </div>
                </div>
                <div class="form-group">
                    <label>Home Location</label>
                    <input type="text" name="location" id="location" placeholder="City" required>
                </div>
            </div>

            <!-- Company fields -->
            <div id="companyFields" style="display:none;">
                <div class="form-group">
                    <label>Company Name</label>
                    <input type="text" name="companyName" id="companyName" placeholder="e.g. Marriott Hotels">
                </div>
                <div class="form-group">
                    <label>Business Type</label>
                    <select name="businessType" id="businessType"
                        style="width:100%; padding:10px; border-radius:8px; border:1px solid #ccc;">
                        <option value="hotel">Hotel</option>
                        <option value="transportation">Transportation</option>
                        <option value="both">Both</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>Phone (optional)</label>
                    <input type="text" name="phone" placeholder="e.g. 555-123-4567">
                </div>
            </div>

            <button type="submit" class="btn btn-primary btn-full">Create Account</button>

        </form>

        <script>
        function toggleFields() {
            var type = document.getElementById('accountType').value;
            var tf = document.getElementById('travelerFields');
            var cf = document.getElementById('companyFields');
            if (type === 'company') {
                tf.style.display = 'none';
                cf.style.display = 'block';
                document.getElementById('firstName').removeAttribute('required');
                document.getElementById('lastName').removeAttribute('required');
                document.getElementById('location').removeAttribute('required');
                document.getElementById('companyName').setAttribute('required', 'required');
            } else {
                tf.style.display = 'block';
                cf.style.display = 'none';
                document.getElementById('firstName').setAttribute('required', 'required');
                document.getElementById('lastName').setAttribute('required', 'required');
                document.getElementById('location').setAttribute('required', 'required');
                document.getElementById('companyName').removeAttribute('required');
            }
        }
        </script>

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