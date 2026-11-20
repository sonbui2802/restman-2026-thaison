# Kiểm thử RestMan6

## Kết quả trên máy bàn giao

- JDK 21.0.12; Maven 3.9.9; Tomcat 9.0.98; MySQL 8.0.43.
- Build WAR thành công, target Java 11.
- **8 test tích hợp DAO: 8 đạt, 0 lỗi, 0 bỏ qua** khi bật cấu hình kiểm thử.
- Kiểm tra HTTP toàn bộ hai luồng trên Tomcat đạt, dùng tài khoản JDBC restman đúng quyền runtime.
- Các JSP của hai module đã được Tomcat biên dịch và phục vụ HTTP 200 khi đúng quyền.
- Trang sai quyền trả HTTP 403; người chưa đăng nhập được chuyển sang Login6.jsp.
- Hash schema gốc trước/sau trùng nhau, đủ 23 bảng.
- Dữ liệu do kiểm tra HTTP tạo ra đã được dọn khỏi database demo sau khi kiểm thử.
- Sau khi bổ sung cách chạy IntelliJ: build lại thành công, 8/8 test DAO đạt; chạy Tomcat qua Cargo và kiểm tra HTTP đạt với kết nối đọc trực tiếp từ db.properties (không dùng biến môi trường DB trong tiến trình web).

## 8 test DAO trên MySQL thực

[Test source](src/test/java/dao/DaoIntegrationTest.java)

1. Đăng nhập đúng/sai mật khẩu, đúng loại khách/quản lý, chuỗi SQL injection không vượt đăng nhập.
2. Thêm món và đọc lại đúng tiếng Việt, dấu nháy, chuỗi giống thẻ HTML.
3. Không lưu giá NaN, Infinity hoặc âm.
4. Lưu đặt nhiều bàn, ghi chú tiếng Việt, khóa chính phát sinh và đầy đủ chi tiết trong một transaction.
5. Chặn khung giờ chồng lấn; cho phép hai khoảng liền nhau; truy vấn bàn trống phản ánh đúng.
6. Không tạo bản ghi khi thiếu sức chứa, bàn lặp hoặc thời gian quá khứ.
7. FK khách không hợp lệ làm rollback; sau rollback vẫn lưu được đặt bàn hợp lệ.
8. Hai kết nối JDBC đồng thời đặt cùng bàn/cùng giờ: chính xác một yêu cầu thành công.

Các test tự tạo fixture có tên ngẫu nhiên và dọn các hàng fixture sau khi chạy. Chỉ được bật với URL trỏ tới **restman_test6**, không dùng schema restman nghiệp vụ.

### Tạo schema kiểm thử riêng

Trong MySQL client (schema mới, chỉ import một lần):

```sql
CREATE DATABASE restman_test6 CHARACTER SET utf8mb4;
USE restman_test6;
SOURCE E:/restman-code/restman6_schema.sql;
ALTER TABLE tblTableReservation6 ADD COLUMN note VARCHAR(255);
INSERT INTO tblMember6(username,password,fullName,role)
VALUES ('managerson',SHA2('12345678',256),'Manager','MANAGER');
SET @manager6=LAST_INSERT_ID();
INSERT INTO tblStaff6(id,position) VALUES(@manager6,'Manager');
INSERT INTO tblManager6(id) VALUES(@manager6);
```

Dùng tài khoản MySQL kiểm thử có quyền SELECT/INSERT/UPDATE/DELETE trên schema kiểm thử. Ví dụ terminal PowerShell:

```powershell
$env:RESTMAN_DB_URL = 'jdbc:mysql://127.0.0.1:3307/restman_test6?useUnicode=true&characterEncoding=UTF-8&connectionTimeZone=Asia/Ho_Chi_Minh'
$env:RESTMAN_DB_USER = 'root'
$env:RESTMAN_DB_PASSWORD = ''
$env:RESTMAN_INTEGRATION_TESTS = 'true'
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1
```

Chỉnh cổng và mật khẩu đúng MySQL của bạn. Báo cáo Surefire được tạo ở thư mục target/surefire-reports sau build.

**Trước khi chạy web trong cùng terminal**, xóa cờ test và đổi URL về schema restman, tài khoản restman như README; đừng dùng URL restman_test6 để chạy ứng dụng demo.

```powershell
Remove-Item Env:RESTMAN_INTEGRATION_TESTS -ErrorAction SilentlyContinue
$env:RESTMAN_DB_URL = 'jdbc:mysql://127.0.0.1:3307/restman?useUnicode=true&characterEncoding=UTF-8&connectionTimeZone=Asia/Ho_Chi_Minh'
$env:RESTMAN_DB_USER = 'restman'
$env:RESTMAN_DB_PASSWORD = 'restman123'
```

## Kiểm tra HTTP và giao diện

[verify-http.ps1](scripts/verify-http.ps1) dùng HttpClient + cookie session, chạy với **PowerShell 7** để đọc chuỗi tiếng Việt UTF-8:

```powershell
pwsh -NoProfile -File scripts/verify-http.ps1
```

Không dùng -WriteData: kiểm tra đăng nhập/phân quyền, dữ liệu sai và luồng đến form xác nhận, không INSERT món/đặt bàn.

Chạy trọn luồng có lưu dữ liệu:

```powershell
pwsh -NoProfile -File scripts/verify-http.ps1 -WriteData
```

Lần này tạo một món tên HTTP6-<GUID> và một đặt bàn tên liên hệ HTTP6 Customer, ngày hiện tại + 120 ngày, từ 19:10 đến 21:05, dùng hai bàn đầu tiên. Script in tên món/ngày đặt để đối chiếu; dọn riêng các bản ghi kiểm thử này trước khi chạy lại cùng ngày. Không dùng thao tác xóa toàn bộ bảng.

Với cổng khác:

```powershell
pwsh -NoProfile -File scripts/verify-http.ps1 -BaseUrl http://localhost:8081/restman6
```

Các kiểm tra HTTP đã đạt:

| Trang / tình huống | Kết quả |
|---|---|
| Login | 2 trường, 1 nút; sai mật khẩu bị từ chối |
| ManagerHome | 2 nút: quản lý món và đăng xuất (yêu cầu bổ sung) |
| ManageDish | 8 cột, 1 nút |
| AddDish | 6 trường, 2 nút; từ chối thiếu CSRF và giá NaN; lưu thành công; escape tên món có thẻ HTML |
| CustomerHome | 2 nút: đặt bàn và đăng xuất (yêu cầu bổ sung) |
| SearchTable | 4 trường: ngày, giờ bắt đầu, giờ kết thúc, số khách; 1 nút; từ chối giờ sai, kết thúc <= bắt đầu và đặt quá khứ; giữ lại cả hai giờ khi quay lại |
| SelectTable | 5 cột, 2 nút; không thêm cột id; từ chối id giả và thiếu sức chứa |
| ConfirmReservation | 5 dòng output, 4 trường nhập, 2 nút; kiểm tra email tại JSP; lưu thành công |
| Gửi lại xác nhận | Không tạo thêm đặt bàn |
| Tìm lại cùng giờ | Các bàn đã đặt không còn trong kết quả |
| Đổi vai trò truy cập | HTTP 403 |
| Chưa đăng nhập | Chuyển tới Login6.jsp |

Kiểm tra dữ liệu note qua SQL sau kiểm thử cho thấy chuỗi “Gần cửa sổ” được lưu đúng.

## Kiểm tra cập nhật giờ bắt đầu/kết thúc và bàn mẫu (20/11/2026)

- Build WAR thành công; chạy riêng Tomcat ở cổng 8081, không dừng phiên IntelliJ ở cổng 8080.
- Kiểm thử HTTP đầy đủ với giờ nhập tự do 19:10–21:05 đạt, gồm lưu đặt bàn, kiểm tra trùng và logout. Từ chối giờ sai định dạng/không tồn tại, kết thúc trước hoặc bằng bắt đầu, thời gian quá khứ. Quay lại trang tìm bàn giữ cả hai giờ.
- Truy vấn trực tiếp xác nhận arrivalTime/endTime được lưu đúng hai giờ khách nhập, không đổi về khung 90 phút.
- Seed chạy hai lần vẫn có 20 bàn (thêm 18 bàn, không tạo trùng). Truy vấn theo từng ngày xác nhận 20 bàn chưa có lịch chồng lấn mỗi ngày từ 20 đến hết 27/11/2026 tại thời điểm kiểm tra.
- Đối chiếu schema trên kết nối hiện tại: 23 bảng, 113 cột gốc + 1 cột note; 23 PK và 29 FK đều khớp, không có khác biệt kiểu dữ liệu/nullable/AUTO_INCREMENT. File schema gốc giữ nguyên hash.

## Giới hạn đối chiếu

Các chỗ tài liệu chưa thống nhất được liệt kê ở [DOI_CHIEU.md](DOI_CHIEU.md), gồm note, createAt/createdAt, EndTime/endTime, constructor DAO6, kiểu trả về đơn của searchFreeTables và getter danh sách bổ sung. Chưa triển khai sửa món vì không có thiết kế lớp/phương thức cho chức năng đó.

