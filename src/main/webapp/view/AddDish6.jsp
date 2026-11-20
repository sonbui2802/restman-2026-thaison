<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/manager6.jspf" %>
<%
Category6[] listCategory = new Category6[0];
try (CategoryDAO6 dao = new CategoryDAO6()) { listCategory=dao.getAllCategories(); }
catch (SQLException ex) { application.log("AddDish6.categories",ex); error6="Không tải được danh mục."; }
String txtName=text(request,"txtName"), txtPrice=text(request,"txtPrice"), txtUnit=text(request,"txtUnit");
String txtImage=text(request,"txtImage"), txtDescription=text(request,"txtDescription"), slCategory=text(request,"slCategory");
if ("POST".equals(request.getMethod())) {
    if (!validCsrf(request,session)) error6="Phiên biểu mẫu hết hạn. Vui lòng thử lại.";
    else if (request.getParameter("btnCancel")!=null) { response.sendRedirect("ManageDish6.jsp"); return; }
    else if (error6.isEmpty()) {
        try {
            bounded(txtName,"Tên món ăn",255,true); bounded(txtUnit,"Đơn vị tính",50,true);
            bounded(txtImage,"Đường dẫn ảnh",255,false); bounded(txtDescription,"Mô tả",255,false);
            if (!txtImage.isEmpty() && !(txtImage.matches("https?://[^\\s]+") || txtImage.matches("\\.\\./assets/[^\\s]+")))
                throw new IllegalArgumentException("Ảnh cần là URL http/https hoặc đường dẫn ../assets/.");
            Float price;
            try { price=Float.valueOf(txtPrice); }
            catch (NumberFormatException ex) { throw new IllegalArgumentException("Đơn giá phải là số dương."); }
            if (!Float.isFinite(price) || price<=0) throw new IllegalArgumentException("Đơn giá phải là số dương hữu hạn.");
            Category6 category=null;
            for (Category6 c : listCategory) if (String.valueOf(c.getId()).equals(slCategory)) category=c;
            if (category==null) throw new IllegalArgumentException("Vui lòng chọn danh mục hợp lệ.");
            Dish6 dish6=new Dish6();
            dish6.setName(txtName); dish6.setPrice(price); dish6.setUnit(txtUnit);
            dish6.setImage(txtImage); dish6.setDescription(txtDescription); dish6.setCategory(category);
            try (DishDAO6 dao=new DishDAO6()) {
                if (!dao.addDish(dish6)) throw new IllegalArgumentException("Không thêm được món ăn.");
            }
            session.setAttribute("dishNotice6","Thêm món ăn thành công");
            response.sendRedirect("ManageDish6.jsp"); return;
        } catch (IllegalArgumentException ex) { error6=ex.getMessage(); }
        catch (SQLException ex) { application.log("AddDish6.add",ex); error6="Không lưu được món ăn. Vui lòng kiểm tra cơ sở dữ liệu."; }
    }
}
%>
<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Thêm món ăn</title><link rel="stylesheet" href="../assets/style6.css"></head>
<body><main class="panel form-panel"><h1>Thêm món ăn</h1>
<% if (!error6.isEmpty()) { %><p class="error" role="alert"><%=h(error6)%></p><% } %>
<form method="post"><input type="hidden" name="csrf6" value="<%=h(session.getAttribute("csrf6"))%>">
<div class="field"><label for="txtName">Tên món ăn</label><input id="txtName" name="txtName" maxlength="255" required value="<%=h(txtName)%>"></div>
<div class="field"><label for="slCategory">Danh mục</label><select id="slCategory" name="slCategory" required><% for (Category6 c : listCategory) { %><option value="<%=c.getId()%>" <%=String.valueOf(c.getId()).equals(slCategory)?"selected":""%>><%=h(c.getName())%></option><% } %></select></div>
<div class="field"><label for="txtPrice">Đơn giá</label><input id="txtPrice" name="txtPrice" type="number" min="0.01" step="0.01" required value="<%=h(txtPrice)%>"></div>
<div class="field"><label for="txtUnit">Đơn vị tính</label><input id="txtUnit" name="txtUnit" maxlength="50" required value="<%=h(txtUnit)%>"></div>
<div class="field"><label for="txtImage">Đường dẫn ảnh</label><input id="txtImage" name="txtImage" maxlength="255" value="<%=h(txtImage)%>"></div>
<div class="field"><label for="txtDescription">Mô tả</label><input id="txtDescription" name="txtDescription" maxlength="255" value="<%=h(txtDescription)%>"></div>
<div class="actions"><button class="secondary" type="submit" name="btnCancel" formnovalidate>Hủy</button><button type="submit" name="btnAdd">Thêm món</button></div>
</form></main></body></html>

