<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/customer6.jspf" %>
<%
if ("POST".equals(request.getMethod()) && request.getParameter("btnLogout") != null) {
    if (!validCsrf(request,session)) { response.sendError(403); return; }
    session.invalidate();
    response.sendRedirect("Login6.jsp"); return;
}
%>
<% String notice6=(String)session.getAttribute("reservationNotice6"); session.removeAttribute("reservationNotice6"); %>
<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Trang chủ khách hàng</title><link rel="stylesheet" href="../assets/style6.css"></head>
<body><main class="panel compact home"><h1>Trang chủ khách hàng</h1>
<% if (notice6!=null) { %><p class="success" role="status"><%=h(notice6)%></p><% } %>
<form action="SearchTable6.jsp" method="get"><button type="submit" name="btnReserveTable">Đặt bàn</button></form>
<form method="post" class="logout-form">
<input type="hidden" name="csrf6" value="<%=h(session.getAttribute("csrf6"))%>">
<button type="submit" name="btnLogout" class="secondary">Đăng xuất</button>
</form>
</main></body></html>

