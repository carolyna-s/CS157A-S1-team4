<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>

<%
    // pull the form fields from register.jsp
    String username    = request.getParameter("username");
    String email       = request.getParameter("email");
    String password    = request.getParameter("password");
    String accountType = request.getParameter("accountType");
    if (accountType == null) accountType = "traveler"; // default if dropdown missing

    // traveler only fields
    String firstName   = request.getParameter("firstName");
    String lastName    = request.getParameter("lastName");
    String location    = request.getParameter("location");
    // company only fields
    String companyName = request.getParameter("companyName");
    String businessType = request.getParameter("businessType");
    String phone       = request.getParameter("phone");

    // base required checks (both traveler + company)
    if (username == null || username.trim().isEmpty() ||
        email == null    || email.trim().isEmpty()    ||
        password == null || password.trim().isEmpty()) {
        response.sendRedirect("register.jsp?error=All+fields+are+required.");
        return;
    }

    // role specific required checks
    if ("company".equals(accountType)) {
        if (companyName == null || companyName.trim().isEmpty() ||
            businessType == null || businessType.trim().isEmpty()) {
            response.sendRedirect("register.jsp?error=Company+name+and+business+type+are+required.");
            return;
        }
    } else {
        if (firstName == null || firstName.trim().isEmpty() ||
            lastName == null  || lastName.trim().isEmpty()  ||
            location == null  || location.trim().isEmpty()) {
            response.sendRedirect("register.jsp?error=All+fields+are+required.");
            return;
        }
    }

    // email check logic
    if (!email.contains("@") || !email.contains("."))
    {
        response.sendRedirect("register.jsp?error=Please+enter+a+valid+email+address.");
        return;
    }

    // password length rule 
    if (password.length() < 8)
    {
        response.sendRedirect("register.jsp?error=Password+must+be+at+least+8+characters.");
        return;
    }

    // hash the password with SHA-256
    // per https://docs.oracle.com/javase/8/docs/api/java/security/MessageDigest.html
    String hashedPassword = "";
    try
    {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        byte[] hashBytes = digest.digest(password.getBytes(StandardCharsets.UTF_8));
        // convert raw bytes -> hex string for storing in VARCHAR
        StringBuilder hexString = new StringBuilder();
        for (byte b : hashBytes)
        {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) hexString.append('0'); // pad single-digit hex
            hexString.append(hex);
        }
        hashedPassword = hexString.toString();
    }
    catch (Exception e)
    {
        response.sendRedirect("register.jsp?error=Server+error+during+registration.");
        return;
    }

    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try
    {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // check that username + email arent already taken 
        pstmt = con.prepareStatement(
            "SELECT userID FROM Users WHERE username = ? OR email = ?"
        );
        pstmt.setString(1, username.trim());
        pstmt.setString(2, email.trim());
        rs = pstmt.executeQuery();
        // we can show error message when that fails
        if (rs.next())
        {
            rs.close();
            pstmt.close();
            con.close();
            response.sendRedirect("register.jsp?error=Username+or+email+already+exists.");
            return;
        }
        rs.close();
        pstmt.close();

        // insert into ussers + grab the auto-generated userID so we can insert
        // into the right subclass table next
        // RETURN_GENERATED_KEYS docs: https://docs.oracle.com/javase/8/docs/api/java/sql/Statement.html#RETURN_GENERATED_KEYS
        pstmt = con.prepareStatement(
            "INSERT INTO Users (email, username, password, account_status) VALUES (?, ?, ?, 'active')",
            Statement.RETURN_GENERATED_KEYS
        );
        pstmt.setString(1, email.trim());
        pstmt.setString(2, username.trim());
        pstmt.setString(3, hashedPassword);
        pstmt.executeUpdate();

        rs = pstmt.getGeneratedKeys();
        int newUserID = 0;
        if (rs.next()) {
            newUserID = rs.getInt(1); // pk of the new Users row
        }
        rs.close();
        pstmt.close();

        if ("company".equals(accountType)) {
            // companies start as pending because an admin has to approve them
            // before they can post listings
            pstmt = con.prepareStatement(
                "INSERT INTO Company (userID, name, business_type, phone, approval_status) VALUES (?, ?, ?, ?, 'pending')"
            );
            pstmt.setInt(1, newUserID);
            pstmt.setString(2, companyName.trim());
            pstmt.setString(3, businessType.trim());
            pstmt.setString(4, (phone != null && !phone.trim().isEmpty()) ? phone.trim() : null);
            pstmt.executeUpdate();
            pstmt.close();

            // row for the ISA relationship (User -> Company) per the report
            pstmt = con.prepareStatement("INSERT INTO Is_A_Company (userID) VALUES (?)");
            pstmt.setInt(1, newUserID);
            pstmt.executeUpdate();
            pstmt.close();
        } else {
            // default is the traveler subclass
            pstmt = con.prepareStatement(
                "INSERT INTO Traveler (userID, firstName, lastName, current_location) VALUES (?, ?, ?, ?)"
            );
            pstmt.setInt(1, newUserID);
            pstmt.setString(2, firstName.trim());
            pstmt.setString(3, lastName.trim());
            pstmt.setString(4, location.trim());
            pstmt.executeUpdate();
            pstmt.close();

            // relation row for User -> Traveler per the report
            pstmt = con.prepareStatement("INSERT INTO Is_A_Traveller (userID) VALUES (?)");
            pstmt.setInt(1, newUserID);
            pstmt.executeUpdate();
            pstmt.close();
        }

        con.close();
        // bounce back to login with a success banner
        response.sendRedirect("login.jsp?success=Account+created+successfully.+Please+sign+in.");

    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("register.jsp?error=Registration+failed.+Please+try+again.");
    }
%>

