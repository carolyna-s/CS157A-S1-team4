<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>

<%
    String username = request.getParameter("username");
    String email = request.getParameter("email");
    String password = request.getParameter("password");
    String firstName = request.getParameter("firstName");
    String lastName = request.getParameter("lastName");
    String location = request.getParameter("location");

    if (username == null || username.trim().isEmpty() || email == null    || email.trim().isEmpty() ||
        password == null || password.trim().isEmpty() || firstName == null || firstName.trim().isEmpty() ||
        lastName == null  || lastName.trim().isEmpty() || location == null  || location.trim().isEmpty()) 
    {
        response.sendRedirect("register.jsp?error=All+fields+are+required.");
        return;
    }

    if (!email.contains("@") || !email.contains(".")) 
    {
        response.sendRedirect("register.jsp?error=Please+enter+a+valid+email+address.");
        return;
    }

    if (password.length() < 8) 
    {
        response.sendRedirect("register.jsp?error=Password+must+be+at+least+8+characters.");
        return;
    }

    String hashedPassword = "";
    try 
    {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        byte[] hashBytes = digest.digest(password.getBytes(StandardCharsets.UTF_8));
        StringBuilder hexString = new StringBuilder();
        for (byte b : hashBytes) 
        {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) hexString.append('0');
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

        pstmt = con.prepareStatement(
            "SELECT userID FROM Users WHERE username = ? OR email = ?"
        );
        pstmt.setString(1, username.trim());
        pstmt.setString(2, email.trim());
        rs = pstmt.executeQuery();

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
            newUserID = rs.getInt(1);
        }
        rs.close();
        pstmt.close();

        pstmt = con.prepareStatement(
            "INSERT INTO Traveler (userID, firstName, lastName, current_location) VALUES (?, ?, ?, ?)"
        );
        pstmt.setInt(1, newUserID);
        pstmt.setString(2, firstName.trim());
        pstmt.setString(3, lastName.trim());
        pstmt.setString(4, location.trim());
        pstmt.executeUpdate();
        pstmt.close();

        pstmt = con.prepareStatement(
            "INSERT INTO Is_A_Traveller (userID) VALUES (?)"
        );
        pstmt.setInt(1, newUserID);
        pstmt.executeUpdate();
        pstmt.close();

        con.close();
        response.sendRedirect("login.jsp?success=Account+created+successfully.+Please+sign+in.");

    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("register.jsp?error=Registration+failed.+Please+try+again.");
    }
%>

