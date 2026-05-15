<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="/WEB-INF/db_config.jsp" %>
<%
    // must be signed in to send a support query
    Integer userID = (Integer) session.getAttribute("userID");
    if (userID == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // form fields from submit_query.jsp
    String subject = request.getParameter("subject");
    String body    = request.getParameter("message_body");

    // both fields required any of the empty messages arent useful for admins
    if (subject == null || subject.trim().isEmpty() ||
        body == null    || body.trim().isEmpty()) {
        response.sendRedirect("submit_query.jsp?error=Subject+and+message+are+required.");
        return;
    }

    Connection con = null;
    PreparedStatement pstmt = null;
    try {
        Class.forName(DB_DRIVER);
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // insert into support queries, they start as open, then admin can move them
        pstmt = con.prepareStatement(
            "INSERT INTO Support_Queries (userID, subject, message_body, query_status) VALUES (?, ?, ?, 'open')",
            Statement.RETURN_GENERATED_KEYS
        );
        pstmt.setInt(1, userID);
        pstmt.setString(2, subject.trim());
        pstmt.setString(3, body.trim());
        pstmt.executeUpdate();

        ResultSet keys = pstmt.getGeneratedKeys();
        int newQueryID = 0;
        if (keys.next()) newQueryID = keys.getInt(1);
        keys.close();
        pstmt.close();

        // per report we have this table for the relationship
        pstmt = con.prepareStatement("INSERT INTO Submits (userID, queryID) VALUES (?, ?)");
        pstmt.setInt(1, userID);
        pstmt.setInt(2, newQueryID);
        pstmt.executeUpdate();
        pstmt.close();

        con.close();
        // back to the same page with a success banner so user sees confirmation
        response.sendRedirect("submit_query.jsp?success=Your+query+has+been+submitted.");
    } catch (Exception e) {
        e.printStackTrace();
        if (con != null) try { con.close(); } catch (Exception ex) {}
        response.sendRedirect("submit_query.jsp?error=Could+not+submit+query.+Please+try+again.");
    }
%>
