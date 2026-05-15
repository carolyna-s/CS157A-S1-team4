<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // wipe out the session so userID/username are gone
    // per https://docs.oracle.com/javaee/7/api/javax/servlet/http/HttpSession.html#invalidate--
    session.invalidate();

    // back to login page 
    response.sendRedirect("login.jsp");
%>