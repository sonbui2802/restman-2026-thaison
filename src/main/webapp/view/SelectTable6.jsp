<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/customer6.jspf" %>
<%
LocalDateTime arrivalTime=(LocalDateTime)session.getAttribute("arrivalTime6");
LocalDateTime endTime=(LocalDateTime)session.getAttribute("endTime6");
Integer guestNumber=(Integer)session.getAttribute("guestNumber6");
if (arrivalTime==null || endTime==null || guestNumber==null) { response.sendRedirect("SearchTable6.jsp"); return; }
DiningTable6[] listTable=new DiningTable6[0];
DiningTable6[] selectedTables=(DiningTable6[])session.getAttribute("selectedTables6");
Set<String> checked6=new HashSet<>();
if (selectedTables!=null) for (DiningTable6 table:selectedTables) checked6.add(String.valueOf(table.getId()));
if ("POST".equals(request.getMethod()) && validCsrf(request,session) && request.getParameter("btnBack")!=null) {
    response.sendRedirect("SearchTable6.jsp"); return;
}
try (DiningTableDAO6 dao=new DiningTableDAO6()) {
    dao.searchFreeTables(arrivalTime,endTime);
    listTable=dao.getListTable();
}
catch (SQLException ex) { application.log("SelectTable6",ex); error6="Không tải được danh sách bàn trống."; }
if ("POST".equals(request.getMethod())) {
    if (!validCsrf(request,session)) error6="Phiên biểu mẫu hết hạn. Vui lòng thử lại.";
    else if (error6.isEmpty()) {
        try {
            String[] values=request.getParameterValues("chkTables");
            checked6.clear(); if (values!=null) checked6.addAll(Arrays.asList(values));
            if (values==null || values.length==0) throw new IllegalArgumentException("Vui lòng chọn ít nhất một bàn.");
            if (checked6.size()!=values.length) throw new IllegalArgumentException("Danh sách bàn không hợp lệ.");
            ArrayList<DiningTable6> chosen=new ArrayList<>();
            long capacity=0;
            for (DiningTable6 table:listTable) if (checked6.contains(String.valueOf(table.getId()))) {
                chosen.add(table); capacity+=table.getCapacity();
            }
            if (chosen.size()!=checked6.size()) throw new IllegalArgumentException("Có bàn vừa được đặt hoặc lựa chọn không hợp lệ. Vui lòng chọn lại.");
            if (capacity<guestNumber) throw new IllegalArgumentException("Tổng sức chứa các bàn chưa đủ cho số khách.");
            session.setAttribute("selectedTables6",chosen.toArray(new DiningTable6[0]));
            session.removeAttribute("reservation6");
            response.sendRedirect("ConfirmReservation6.jsp"); return;
        } catch (IllegalArgumentException ex) { error6=ex.getMessage(); }
    }
}
%>
<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Chọn bàn trống</title><link rel="stylesheet" href="../assets/style6.css"></head>
<body><main class="panel tables-panel"><h1>Chọn bàn trống</h1>
<p class="reservation-time">Ngày <%=arrivalTime.format(DATE6)%> khung giờ <%=arrivalTime.format(TIME6)%> - <%=endTime.format(TIME6)%></p>
<p><strong>Danh sách bàn trống:</strong></p>
<% if (!error6.isEmpty()) { %><p class="error" role="alert"><%=h(error6)%></p><% } %>
<% if (listTable.length==0 && error6.isEmpty()) { %><p role="status">Không có bàn trống trong khung giờ này.</p><% } %>
<form method="post"><input type="hidden" name="csrf6" value="<%=h(session.getAttribute("csrf6"))%>">
<div class="table-wrap"><table id="tblTable"><thead><tr><th>Chọn</th><th>Tên bàn</th><th>Sức chứa</th><th>Vị trí</th><th>Mô tả</th></tr></thead>
<tbody><% for (DiningTable6 table:listTable) { %><tr>
<td><input type="checkbox" name="chkTables" value="<%=table.getId()%>" aria-label="Chọn <%=h(table.getName())%>" <%=checked6.contains(String.valueOf(table.getId()))?"checked":""%>></td>
<td><%=h(table.getName())%></td><td><%=table.getCapacity()%> người</td><td><%=h(table.getLocation())%></td><td><%=h(table.getDescription())%></td>
</tr><% } %></tbody></table></div>
<div class="actions"><button type="submit" class="secondary" name="btnBack" formnovalidate>Quay lại</button><button type="submit" name="btnContinue">Tiếp tục</button></div>
</form></main></body></html>

