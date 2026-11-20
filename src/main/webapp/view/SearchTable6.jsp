<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/customer6.jspf" %>
<%
String inDate=text(request,"inDate"), inStartTime=text(request,"inStartTime");
String inEndTime=text(request,"inEndTime"), inGuestNumber=text(request,"inGuestNumber");
if (!"POST".equals(request.getMethod()) && inDate.isEmpty())
    inDate=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).toString();
if (!"POST".equals(request.getMethod()) && session.getAttribute("arrivalTime6")!=null) {
    LocalDateTime oldArrival=(LocalDateTime)session.getAttribute("arrivalTime6");
    LocalDateTime oldEnd=(LocalDateTime)session.getAttribute("endTime6");
    inDate=oldArrival.toLocalDate().toString();
    inStartTime=oldArrival.format(TIME6);
    inEndTime=oldEnd.format(TIME6);
    inGuestNumber=String.valueOf(session.getAttribute("guestNumber6"));
}
if ("POST".equals(request.getMethod())) {
    if (!validCsrf(request,session)) error6="Phiên biểu mẫu hết hạn. Vui lòng thử lại.";
    else {
        try {
            LocalDate date;
            LocalTime startTime, finishTime;
            int guestNumber;
            try { date=LocalDate.parse(inDate); guestNumber=Integer.parseInt(inGuestNumber); }
            catch (DateTimeException | NumberFormatException ex) { throw new IllegalArgumentException("Ngày hoặc số khách không hợp lệ."); }
            if (!inStartTime.matches("[0-9]{2}:[0-9]{2}") || !inEndTime.matches("[0-9]{2}:[0-9]{2}"))
                throw new IllegalArgumentException("Vui lòng nhập giờ bắt đầu và giờ kết thúc hợp lệ.");
            try { startTime=LocalTime.parse(inStartTime); finishTime=LocalTime.parse(inEndTime); }
            catch (DateTimeException ex) { throw new IllegalArgumentException("Vui lòng nhập giờ bắt đầu và giờ kết thúc hợp lệ."); }
            if (guestNumber<=0) throw new IllegalArgumentException("Số khách phải là số nguyên dương.");
            LocalDateTime arrivalTime=LocalDateTime.of(date,startTime);
            LocalDateTime endTime=LocalDateTime.of(date,finishTime);
            if (!endTime.isAfter(arrivalTime))
                throw new IllegalArgumentException("Giờ kết thúc phải sau giờ bắt đầu trong cùng ngày.");
            if (!arrivalTime.isAfter(LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"))))
                throw new IllegalArgumentException("Vui lòng chọn thời gian trong tương lai.");
            session.setAttribute("arrivalTime6",arrivalTime); session.setAttribute("endTime6",endTime);
            session.setAttribute("guestNumber6",guestNumber); session.removeAttribute("selectedTables6");
            session.removeAttribute("reservation6");
            response.sendRedirect("SelectTable6.jsp"); return;
        } catch (IllegalArgumentException ex) { error6=ex.getMessage(); }
    }
}
%>
<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Tìm bàn trống</title><link rel="stylesheet" href="../assets/style6.css"></head>
<body><main class="panel compact"><h1>Tìm bàn trống</h1>
<% if (!error6.isEmpty()) { %><p class="error" role="alert"><%=h(error6)%></p><% } %>
<form method="post"><input type="hidden" name="csrf6" value="<%=h(session.getAttribute("csrf6"))%>">
<div class="field"><label for="inDate">Nhập ngày</label><input id="inDate" name="inDate" type="date" min="<%=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"))%>" required value="<%=h(inDate)%>"></div>
<div class="field"><label for="inStartTime">Giờ bắt đầu</label><input id="inStartTime" name="inStartTime" type="time" step="60" required value="<%=h(inStartTime)%>"></div>
<div class="field"><label for="inEndTime">Giờ kết thúc</label><input id="inEndTime" name="inEndTime" type="time" step="60" required value="<%=h(inEndTime)%>"></div>
<div class="field"><label for="inGuestNumber">Nhập số khách</label><input id="inGuestNumber" name="inGuestNumber" type="number" min="1" max="2147483647" step="1" required value="<%=h(inGuestNumber)%>"></div>
<div class="actions"><button type="submit" name="btnSearch">Tìm kiếm</button></div>
</form></main></body></html>

