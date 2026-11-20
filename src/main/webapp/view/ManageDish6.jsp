<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/manager6.jspf" %>
<%
Dish6[] listDish = new Dish6[0];
try (DishDAO6 dao = new DishDAO6()) { listDish=dao.getAllDishes(); }
catch (SQLException ex) { application.log("ManageDish6",ex); error6="Không tải được danh sách món ăn."; }
String notice6=(String)session.getAttribute("dishNotice6"); session.removeAttribute("dishNotice6");
%>
<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Quản lý món ăn</title><link rel="stylesheet" href="../assets/style6.css"></head>
<body><main class="panel wide"><h1>Quản lý món ăn</h1>
<% if (notice6!=null) { %><p class="success" role="status"><%=h(notice6)%></p><% } %>
<% if (!error6.isEmpty()) { %><p class="error" role="alert"><%=h(error6)%></p><% } %>
<form action="AddDish6.jsp" method="get" class="actions"><button type="submit" name="btnAddDish">Thêm món ăn</button></form>
<div class="table-wrap"><table id="tblDish"><thead><tr><th>id</th><th>Tên món ăn</th><th>Danh mục</th><th>Đơn vị tính</th><th>Ảnh</th><th>Đơn giá</th><th>Mô tả</th><th>Sửa</th></tr></thead>
<tbody><% for (Dish6 dish : listDish) { %><tr>
<td><%=dish.getId()%></td><td><%=h(dish.getName())%></td><td><%=h(dish.getCategory()==null ? "" : dish.getCategory().getName())%></td><td><%=h(dish.getUnit())%></td>
<td><% if (dish.getImage()!=null && !dish.getImage().isBlank() && (dish.getImage().matches("https?://.*") || dish.getImage().startsWith("../assets/"))) { %><img class="dish-image" src="<%=h(dish.getImage())%>" alt="<%=h(dish.getName())%>"><% } else { %><%=h(dish.getImage())%><% } %></td>
<td class="price"><%=dish.getPrice()==null ? "" : h(String.format(java.util.Locale.forLanguageTag("vi-VN"),"%,.0f",dish.getPrice()))%></td><td><%=h(dish.getDescription())%></td><td><span class="muted" title="Chưa có thiết kế chức năng sửa món">(click để sửa)</span></td>
</tr><% } %></tbody></table></div>
</main></body></html>

