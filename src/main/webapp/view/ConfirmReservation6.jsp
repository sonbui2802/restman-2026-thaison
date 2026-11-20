<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/customer6.jspf" %>
<%
LocalDateTime arrivalTime=(LocalDateTime)session.getAttribute("arrivalTime6");
LocalDateTime endTime=(LocalDateTime)session.getAttribute("endTime6");
Integer guestNumber=(Integer)session.getAttribute("guestNumber6");
DiningTable6[] selectedTables=(DiningTable6[])session.getAttribute("selectedTables6");
if (arrivalTime==null || endTime==null || guestNumber==null) { response.sendRedirect("SearchTable6.jsp"); return; }
if (selectedTables==null || selectedTables.length==0) { response.sendRedirect("SelectTable6.jsp"); return; }
TableReservation6 reservation=(TableReservation6)session.getAttribute("reservation6");
String inName=reservation==null ? customer.getFullName() : reservation.getContactName();
String inPhone=reservation==null ? customer.getPhone() : reservation.getContactPhone();
String inEmail=reservation==null ? customer.getEmail() : reservation.getContactEmail();
String inNote=reservation==null ? "" : reservation.getNote();
if ("POST".equals(request.getMethod())) {
    inName=text(request,"inName"); inPhone=text(request,"inPhone"); inEmail=text(request,"inEmail"); inNote=text(request,"inNote");
    if (!validCsrf(request,session)) error6="Phiên biểu mẫu hết hạn. Vui lòng thử lại.";
    else {
        reservation=new TableReservation6();
        reservation.setArrivalTime(arrivalTime); reservation.setEndTime(endTime);
        reservation.setGuestNumber(guestNumber); reservation.setCustomer(customer);
        reservation.setContactName(inName); reservation.setContactPhone(inPhone);
        reservation.setContactEmail(inEmail); reservation.setNote(inNote);
        ReservationDetail6[] details=new ReservationDetail6[selectedTables.length];
        for (int i=0;i<selectedTables.length;i++) { details[i]=new ReservationDetail6(); details[i].setDiningTable(selectedTables[i]); }
        reservation.setReservationDetails(details);
        session.setAttribute("reservation6",reservation);
        if (request.getParameter("btnCancel")!=null) { response.sendRedirect("SelectTable6.jsp"); return; }
        try {
            bounded(inName,"Họ tên",255,true); bounded(inPhone,"SĐT",20,true);
            bounded(inEmail,"Email",255,false); bounded(inNote,"Ghi chú",255,false);
            if (!inPhone.matches("\\+?[0-9][0-9 .()\\-]{7,19}")) throw new IllegalArgumentException("SĐT không hợp lệ.");
            if (!inEmail.isEmpty() && !inEmail.matches("[^\\s@]+@[^\\s@]+\\.[^\\s@]+"))
                throw new IllegalArgumentException("Email không hợp lệ.");
            // Serialize duplicate confirmations for the same session; the database handles other sessions.
            synchronized (session) {
                if (session.getAttribute("selectedTables6")==null) {
                    response.sendRedirect("CustomerHome6.jsp"); return;
                }
                boolean saved;
                try (TableReservationDAO6 dao=new TableReservationDAO6()) { saved=dao.saveReservation(reservation); }
                if (!saved) throw new IllegalArgumentException("Không thể đặt bàn: thời gian đã qua, bàn vừa được đặt hoặc không đủ sức chứa. Vui lòng quay lại chọn bàn.");
                session.removeAttribute("arrivalTime6"); session.removeAttribute("endTime6");
                session.removeAttribute("guestNumber6"); session.removeAttribute("selectedTables6"); session.removeAttribute("reservation6");
                session.setAttribute("reservationNotice6","Đặt bàn thành công");
            }
            response.sendRedirect("CustomerHome6.jsp"); return;
        } catch (IllegalArgumentException ex) { error6=ex.getMessage(); }
        catch (SQLException ex) { application.log("ConfirmReservation6",ex); error6="Không lưu được đặt bàn. Vui lòng kiểm tra cơ sở dữ liệu và migration note."; }
    }
}
long totalCapacity=0; StringJoiner tableNames=new StringJoiner(", ");
for (DiningTable6 table:selectedTables) { totalCapacity+=table.getCapacity(); tableNames.add(table.getName()); }
%>
<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Xác nhận đặt bàn</title><link rel="stylesheet" href="../assets/style6.css"></head>
<body><main class="panel form-panel"><h1>Xác nhận đặt bàn</h1>
<% if (!error6.isEmpty()) { %><p class="error" role="alert"><%=h(error6)%></p><% } %>
<div id="outReservationInfo" class="summary">
<div class="field"><span class="label">Ngày đặt</span><output><%=arrivalTime.format(DATE6)%></output></div>
<div class="field"><span class="label">Thời gian</span><output><%=arrivalTime.format(TIME6)%> - <%=endTime.format(TIME6)%></output></div>
<div class="field"><span class="label">Số khách</span><output><%=guestNumber%> người</output></div>
<div class="field"><span class="label">Bàn đã chọn</span><output><%=h(tableNames)%></output></div>
<div class="field"><span class="label">Tổng sức chứa</span><output><%=totalCapacity%> người</output></div>
</div>
<p><strong>Vui lòng nhập thông tin:</strong></p>
<form method="post"><input type="hidden" name="csrf6" value="<%=h(session.getAttribute("csrf6"))%>">
<div class="field"><label for="inName">Họ tên</label><input id="inName" name="inName" maxlength="255" required value="<%=h(inName)%>"></div>
<div class="field"><label for="inPhone">SĐT</label><input id="inPhone" name="inPhone" type="tel" maxlength="20" required value="<%=h(inPhone)%>"></div>
<div class="field"><label for="inEmail">Email</label><input id="inEmail" name="inEmail" type="email" maxlength="255" value="<%=h(inEmail)%>"></div>
<div class="field"><label for="inNote">Ghi chú</label><textarea id="inNote" name="inNote" maxlength="255" rows="2"><%=h(inNote)%></textarea></div>
<div class="actions"><button type="submit" class="secondary" name="btnCancel" formnovalidate>Quay lại</button><button type="submit" name="btnConfirm">Xác nhận</button></div>
</form></main></body></html>

