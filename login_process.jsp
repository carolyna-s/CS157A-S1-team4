<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>

<%
    String username = request.getParameter("username");
    String password = request.getParameter("password");

    if (username == null || username.trim().isEmpty() || password == null || password.trim().isEmpty()) 
    {
        response.sendRedirect("login.jsp?error=Please+enter+both+username+and+password.");
        return;
    }

    String hashedPassword = "";
    try 
    {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        byte[] hashBytes = digest.digest(password.getBytes(StandardCharsets.UTF_8));
        StringBuilder hexString = new StringBuilder();
        for (byte b : hashBytes) {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) hexString.append('0');
            hexString.append(hex);
        }
        hashedPassword = hexString.toString();
    } 
    catch (Exception e) 
    {
        response.sendRedirect("login.jsp?error=Server+error.+Please+try+again.");
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
            "SELECT u.userID, u.username, t.firstName, t.lastName " +
            "FROM Users u " +
            "JOIN Traveler t ON u.userID = t.userID " +
            "WHERE u.username = ? AND u.password = ? AND u.account_status = 'active'"
        );
        pstmt.setString(1, username.trim());
        pstmt.setString(2, hashedPassword);
        rs = pstmt.executeQuery();
        if (rs.next()) 
        {
            int userID       = rs.getInt("userID");
            String uname     = rs.getString("username");
            String firstName = rs.getString("firstName");
            String lastName  = rs.getString("lastName");

            rs.close();
            pstmt.close();
            con.close();

            HttpSession userSession = request.getSession(true);
            userSession.setAttribute("userID", userID);
            userSession.setAttribute("username", uname);
            userSession.setAttribute("firstName", firstName);
            userSession.setAttribute("lastName", lastName);

            response.sendRedirect("dashboard.jsp");
        } 
        else 
        {
            rs.close();
            pstmt.close();
            con.close();

            response.sendRedirect("login.jsp?error=Invalid+username+or+password.");
        }
    } 
    catch (Exception e) 
    {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("login.jsp?error=Login+failed.+Please+try+again.");
    }
%>