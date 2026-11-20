<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/common6.jspf" %>
<%
if (member6 != null) {
    response.sendRedirect("MANAGER".equals(member6.getRole()) ? "ManagerHome6.jsp" : "CustomerHome6.jsp"); return;
}
String username = text(request,"username");
if ("POST".equals(request.getMethod())) {
    if (!validCsrf(request,session)) error6 = "Phiên biểu mẫu hết hạn. Vui lòng thử lại.";
    else {
        try {
            bounded(username,"Tài khoản",100,true);
            String password = request.getParameter("password");
            if (password == null || password.isEmpty() || password.length()>255)
                throw new IllegalArgumentException("Vui lòng nhập mật khẩu hợp lệ.");
            try (MemberDAO6 dao = new MemberDAO6()) { member6 = dao.authenticate(username,password); }
            if (member6 == null) error6 = "Tài khoản hoặc mật khẩu không đúng.";
            else {
                request.changeSessionId();
                session.setAttribute("csrf6",UUID.randomUUID().toString());
                session.setAttribute("member6",member6);
                response.sendRedirect("MANAGER".equals(member6.getRole()) ? "ManagerHome6.jsp" : "CustomerHome6.jsp"); return;
            }
        } catch (IllegalArgumentException ex) { error6=ex.getMessage(); }
        catch (SQLException ex) { application.log("Login6",ex); error6="Không kết nối được cơ sở dữ liệu. Vui lòng kiểm tra cấu hình."; }
    }
}
%>
<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Đăng nhập</title><link rel="stylesheet" href="../assets/style6.css"></head>
<body><main class="panel compact"><h1>Đăng nhập</h1>
<% if (!error6.isEmpty()) { %><p class="error" role="alert"><%=h(error6)%></p><% } %>
<form method="post">
<input type="hidden" name="csrf6" value="<%=h(session.getAttribute("csrf6"))%>">
<div class="field"><label for="username">Tài khoản</label><input id="username" name="username" maxlength="100" required autocomplete="username" value="<%=h(username)%>"></div>
<div class="field"><label for="password">Mật khẩu</label><input id="password" name="password" type="password" maxlength="255" required autocomplete="current-password"></div>
<div class="actions"><button type="submit" name="btnLogin">Đăng nhập</button></div>
</form></main></body></html>

