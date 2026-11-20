# RestMan6 — JSP + DAO + JDBC + MySQL

Ứng dụng Java Web thuần theo ba phần **model, dao, view**. JSP nhận request, kiểm tra dữ liệu, gọi DAO trực tiếp; DAO dùng JDBC/PreparedStatement. Không dùng Spring, servlet controller, service hoặc repository.

Đã có hai luồng:

- Quản lý → Quản lý món ăn → Thêm món → thông báo thành công.
- Khách hàng → Tìm bàn → Chọn một hoặc nhiều bàn → Xác nhận → lưu đặt bàn.
- Đăng nhập và kiểm tra quyền tại từng JSP.

## Chạy nhanh trong IntelliJ IDEA

1. **File → Open**, chọn thư mục dự án hoặc [pom.xml](pom.xml), mở dưới dạng Maven project. Chọn JDK 11 trở lên và chờ Maven tải thư viện.
2. Sao chép **[src/main/resources/db.properties.example](src/main/resources/db.properties.example)** thành **src/main/resources/db.properties**, rồi điền cấu hình MySQL của máy bạn. File db.properties chứa thông tin riêng nên được Git bỏ qua; không có trong repository.

   ```properties
   db.url=jdbc:mysql://localhost:3306/restman?useUnicode=true&characterEncoding=UTF-8&connectionTimeZone=Asia/Ho_Chi_Minh
   db.username=restman
   db.password=YOUR_MYSQL_PASSWORD
   ```

   Đây là tài khoản **MySQL**, khác tài khoản đăng nhập web. Nếu dùng MySQL root, thay username bằng root và password bằng mật khẩu root của bạn; mật khẩu rỗng thì để `db.password=`. Nếu tạo tài khoản mẫu bằng database/00_database.sql, thông tin mẫu là restman / restman123. MySQL thường dùng cổng **3306**; chỉnh lại nếu máy bạn dùng cổng khác. Database vẫn là restman.
3. Trên thanh Run chọn **RestMan6 - Run Tomcat**, bấm **Run ▶**. Cấu hình đã lưu trong [.run/RestMan6.run.xml](.run/RestMan6.run.xml). Maven tự build WAR, chép vào Tomcat rồi chạy; không cần đặt biến môi trường hoặc cấu hình Deployment thủ công.
4. Khi console báo Tomcat đã khởi động, mở **http://localhost:8080/restman6/**.

Tomcat và Maven tải riêng trong `.tools/` không được đưa lên GitHub. Khi clone về máy khác, cài JDK, dùng Maven tích hợp của IntelliJ, giải nén **Tomcat 9** rồi điền đường dẫn **`tomcat.home` trong [pom.xml](pom.xml)** (ví dụ C:/apache-tomcat-9). Trên máy đã chuẩn bị sẵn, đường dẫn mặc định là `.tools/apache-tomcat-9.0.98`. Cổng web ở **`http.port` trong cùng file**; mặc định 8080. MySQL cần đang chạy và đã import SQL ở phần dưới; trên database đã chuẩn bị thì không import lại.

Nếu IntelliJ chưa hiện cấu hình Run: bấm **Reload All Maven Projects**, hoặc tạo cấu hình **Maven**, Working directory là thư mục dự án, Command line là **`package cargo:run`**. Có thể chạy cùng lệnh trong cửa sổ Maven của IntelliJ; không cần cài Smart Tomcat. Dừng bằng nút Stop; sau khi sửa db.properties, Stop và Run lại để đóng gói cấu hình mới.

Cargo chỉ là Maven plugin để khởi động Tomcat; mã ứng dụng vẫn giữ model / dao / JSP. Hướng dẫn chính thức: [IntelliJ Maven run configuration](https://www.jetbrains.com/help/idea/run-debug-configuration-maven.html), [Cargo Maven plugin](https://codehaus-cargo.github.io/cargo/Maven+3+Plugin+Reference+Guide.html).

## Tài khoản mẫu

| Quyền | Tài khoản | Mật khẩu |
|---|---|---|
| Quản lý | managerson | 12345678 |
| Khách hàng | customer6 | 12345678 |

Tài khoản được tạo bởi [02_demo_data.sql](database/02_demo_data.sql). Mật khẩu mẫu lưu dưới dạng SHA-256 trong cột `password`. Hai trang chủ có nút **Đăng xuất** theo yêu cầu bổ sung: xóa toàn bộ session và chuyển về Login6.jsp. Phiên cũng hết hạn sau 30 phút không hoạt động.

## Yêu cầu

- JDK 11 trở lên; bản bàn giao đã kiểm tra với JDK 21.
- Apache Maven 3.9+.
- **Apache Tomcat 9.x**, dùng Servlet 4 / `javax.servlet`. Không triển khai WAR này trực tiếp trên Tomcat 10/11 dùng `jakarta.servlet`.
- MySQL 8.x; bản bàn giao đã kiểm tra với MySQL 8.0.43.
- Các dependency chỉ có MySQL Connector/J, Servlet API do Tomcat cung cấp và JUnit trong phạm vi test.

## 1. Khởi tạo MySQL

Mở MySQL Command Line Client hoặc terminal:

```text
mysql -u root -p --default-character-set=utf8mb4
```

Chạy lần lượt; thay đường dẫn nếu dự án nằm ở nơi khác:

```sql
SOURCE E:/restman-code/database/00_database.sql;
SOURCE E:/restman-code/restman6_schema.sql;
SOURCE E:/restman-code/database/01_reservation_note.sql;
SOURCE E:/restman-code/database/02_demo_data.sql;
```

[00_database.sql](database/00_database.sql) tạo database `restman`, tài khoản JDBC `restman / restman123`, cấp SELECT/INSERT/UPDATE và chọn database. UPDATE cần cho truy vấn khóa `SELECT ... FOR UPDATE` của MySQL. [Schema gốc](restman6_schema.sql) được giữ nguyên từng byte, tạo đủ 23 bảng. Nếu database đã có 23 bảng, **bỏ qua bước import schema gốc**, tránh lỗi bảng đã tồn tại.

**Điểm cần đối chiếu:** schema gốc thiếu cột `note` của đặt bàn. [01_reservation_note.sql](database/01_reservation_note.sql) bổ sung riêng cột này để ghi chú trên form được lưu. Chạy migration một lần; nếu đã có cột `note`, bỏ qua bước đó. Không đổi tên bảng, cột có sẵn, PK hoặc FK. Xem đầy đủ [DOI_CHIEU.md](DOI_CHIEU.md).

Seed có thể chạy lại, không ghi đè tài khoản hoặc dữ liệu đã tồn tại. Nếu trước đó đã có tài khoản trùng tên nhưng mật khẩu/quyền khác, seed giữ nguyên dữ liệu đó.

## 2. Build WAR

Tại thư mục gốc dự án:

```powershell
mvn clean package
```

Hoặc trên Windows, script tự tìm Maven trong PATH hoặc bản Maven tải sẵn trong thư mục công cụ của dự án:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1
```

Kết quả: [target/restman6.war](target/restman6.war). Thư viện JDBC đã nằm trong WAR, không cần chép thêm vào Tomcat.

Các test MySQL tích hợp chỉ chạy khi bật biến môi trường riêng, tránh tự truy cập database khi build thông thường. Hướng dẫn ở [KIEM_THU.md](KIEM_THU.md).

## 3. Chạy localhost trên Windows

Điền kết nối MySQL trong [db.properties](src/main/resources/db.properties), sau đó chạy:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run-local.ps1
```

Script tự tìm bản Tomcat 9 có sẵn trong dự án. Nếu dùng thư mục Tomcat khác, truyền `-TomcatHome 'C:/apache-tomcat-9'`.

Mở **http://localhost:8080/restman6/**. Script tạo CATALINA_BASE riêng trong thư mục runtime của dự án, chép WAR vào webapps và chạy Tomcat ở foreground. Dừng bằng **Ctrl+C** trong terminal đó.

Nếu đã build, dùng:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run-local.ps1 -SkipBuild
```

Nếu cổng 8080 đang bận:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run-local.ps1 -Port 8081
```

Sau đó mở http://localhost:8081/restman6/. Trong VS Code cũng có task **Build RestMan6 WAR** và **Run RestMan6 localhost**.

### Triển khai vào Tomcat có sẵn

Dừng Tomcat, sửa [db.properties](src/main/resources/db.properties), build lại và chép WAR vào `$CATALINA_HOME/webapps/restman6.war`, rồi chạy `bin/catalina.bat run`.

Linux/macOS cũng sửa db.properties, build bằng Maven, chép WAR vào Tomcat 9/webapps rồi chạy `bin/catalina.sh run`.

Các biến RESTMAN_DB_URL/RESTMAN_DB_USER/RESTMAN_DB_PASSWORD vẫn được hỗ trợ để ghi đè file khi chạy kiểm thử. Khi chạy thông thường trong IntelliJ, để trống phần Environment variables. Nếu đã đặt các biến này trước đó, xóa chúng để cấu hình trong file có hiệu lực.

## Cách thử

1. Đăng nhập `managerson / 12345678`.
2. Chọn **Quản lý Món ăn** → **Thêm món ăn**. Điền đúng 6 trường trên form, bấm **Thêm món**. Bảng món hiển thị bản ghi mới; **Hủy** quay lại và không lưu.
3. Mở cửa sổ ẩn danh, đăng nhập `customer6 / 12345678`.
4. Chọn **Đặt bàn**, ngày, **giờ bắt đầu**, **giờ kết thúc** và số khách. Thời gian bắt đầu phải trong tương lai; giờ kết thúc phải sau giờ bắt đầu trong cùng ngày.
5. Chọn bàn đủ tổng sức chứa. Không có cột id hoặc trường thông tin phụ trên trang chọn bàn.
6. **Tiếp tục**, kiểm tra 5 dòng tóm tắt, nhập 4 trường liên hệ/ghi chú, bấm **Xác nhận**.
7. Tìm lại cùng khung giờ: các bàn vừa đặt không còn trong danh sách trống.

Giờ bắt đầu và kết thúc nhập riêng, chính xác đến phút; không còn danh sách khung giờ cố định 90 phút. Ngày/giờ theo Asia/Ho_Chi_Minh. Bảng bàn dùng `AVAILABLE` hoặc NULL để chỉ bàn hoạt động; đặt bàn lưu `RESERVED`. Đặt bàn có trạng thái `CANCELLED` hoặc `CANCELED` không chặn lịch. Đây là quy ước mẫu vì tài liệu không cho enum trạng thái.

[02_demo_data.sql](database/02_demo_data.sql) có **20 bàn mẫu**, sức chứa 2–10 người. Trên database đã có dữ liệu, chỉ cần chạy lại file seed này để thêm Bàn 03–20; không cần import lại schema. Đã kiểm tra có 20 bàn trống mỗi ngày 20–27/11/2026 trước khi phát sinh đặt mới. Không cần tạo bản ghi “bàn trống” theo từng ngày: DAO tự loại bàn có lịch chồng lấn.

## Cấu trúc

- [model](src/main/java/model): Category6, Dish6, DiningTable6, ReservationDetail6, TableReservation6; Member6/Customer6 phục vụ đăng nhập và liên kết khách hàng.
- [dao](src/main/java/dao): DAO6, CategoryDAO6, DishDAO6, DiningTableDAO6, TableReservationDAO6, MemberDAO6.
- [view](src/main/webapp/view): các JSP đúng luồng của tài liệu.
- [JSP include](src/main/webapp/WEB-INF/jspf): hàm escape, CSRF và kiểm tra session/quyền; vẫn thuộc view, không tạo tầng mới.
- [CSS](src/main/webapp/assets/style6.css): chỉ font, màu, khoảng cách, tỷ lệ và bo góc.
- [SQL bổ sung](database): tạo database, migration note minh bạch và dữ liệu mẫu.

ID, giá, trạng thái, thời gian tạo và khóa ngoại không được thêm vào form nhập khi wireframe không có. Trường hidden duy nhất là token CSRF, không phải thuộc tính nghiệp vụ mới. Tóm tắt đặt bàn dùng output, không thêm input chỉnh sửa.

## Khi gặp lỗi

- Trang báo không kết nối được DB: kiểm tra MySQL đang chạy và URL/tài khoản/mật khẩu trong [db.properties](src/main/resources/db.properties); thử đăng nhập MySQL bằng cùng tài khoản. Sửa file xong cần Stop và Run lại.
- `Unknown column 'note'`: chưa chạy migration bổ sung ở bước 1.
- `Public Key Retrieval is not allowed` trên MySQL localhost không hỗ trợ TLS: cấu hình TLS cho MySQL, hoặc riêng môi trường phát triển thêm `&allowPublicKeyRetrieval=true` vào URL JDBC.
- Chữ tiếng Việt lỗi: import SQL với `--default-character-set=utf8mb4`, giữ file UTF-8.
- Chi tiết lỗi JDBC/JSP nằm trong log Tomcat; giao diện không xuất stack trace.
- Cột **Sửa** giữ theo wireframe nhưng chưa có hành động vì tài liệu chỉ cung cấp thiết kế thêm món.

