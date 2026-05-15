<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>

<%
    // must be logged in
    Integer userID = (Integer) session.getAttribute("userID");

    if (userID == null) {
        response.sendRedirect("login.jsp?error=Invalid+Session.+Please+login+again.");
        return;
    }

    // password reconfirm is required so somebody cant just click the link
    String password = request.getParameter("password");

    if (password == null || password.trim().isEmpty()) {
        response.sendRedirect("delete_account.jsp?error=Please+enter+your+password.");
        return;
    }

    // hash same way register/login does so we can compare
    String hashedPassword = "";
    try {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        byte[] hashBytes = digest.digest(password.getBytes(StandardCharsets.UTF_8));
        StringBuilder hexString = new StringBuilder();
        for (byte b : hashBytes) {
            String hex = Integer.toHexString(0xff & b);
            if (hex.length() == 1) hexString.append('0');
            hexString.append(hex);
        }
        hashedPassword = hexString.toString();
    } catch (Exception e) {
        response.sendRedirect("delete_account.jsp?error=Server+error.+Please+try+again.");
        return;
    }

    Connection con = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // verify the password matches what we have stored before we delete anything
        pstmt = con.prepareStatement(
            "SELECT userID FROM Users WHERE userID = ? AND password = ?"
        );
        pstmt.setInt(1, userID);
        pstmt.setString(2, hashedPassword);
        rs = pstmt.executeQuery();

        if (rs.next()) {
            rs.close();
            pstmt.close();

            // delete from Users + cascade which we have in setup file
            pstmt = con.prepareStatement("DELETE FROM Users WHERE userID = ?");
            pstmt.setInt(1, userID);
            pstmt.executeUpdate();
            pstmt.close();
            con.close();

            // kill the session too
            session.invalidate();
            response.sendRedirect("login.jsp?success=Account+deleted+successfully.");
        } else {
            // password didnt match, delete doesn't go through
            rs.close();
            pstmt.close();
            con.close();

            response.sendRedirect("delete_account.jsp?error=Incorrect+password.+Deletion+cancelled.");
        }
    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) { try { con.close(); } catch(Exception ex) {} }
        response.sendRedirect("delete_account.jsp?error=Deletion+failed.+Please+try+again.");
    }
%>