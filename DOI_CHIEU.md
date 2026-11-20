# Đối chiếu tài liệu, schema và triển khai

## Các điểm chưa thống nhất cần chốt

| Tài liệu | SQL / Java thực tế | Cách xử lý |
|---|---|---|
| TableReservation6 có `note : String`; wireframe có Ghi chú | `tblTableReservation6` gốc không có cột note | Giữ schema gốc nguyên byte; migration riêng thêm `note VARCHAR(255)`. Cần chạy migration để lưu đủ form. Đây là phần bổ sung schema duy nhất. |
| `createAt : LocalDateTime` | SQL `createdAt` | Model giữ `createAt`, DAO ánh xạ vào cột `createdAt`. |
| `EndTime : LocalDateTime` với E hoa | SQL `endTime` | Model giữ `EndTime`, getter/setter getEndTime/setEndTime, tham số searchFreeTables giữ `EndTime`; SQL dùng đúng `endTime`. |
| Category6 có id/name/description | SQL có thêm `attribute` | Model chỉ có đúng 3 thuộc tính; không đọc/ghi attribute, không thêm trường giao diện. |
| DiningTable6 có id/name/capacity/location/description | SQL có thêm `status` | Model giữ đúng 5 thuộc tính; DAO chỉ dùng status trong điều kiện tìm bàn. Không hiển thị thêm cột trạng thái. |
| SQL có `tblSaleStaff6id` trong đặt bàn | Sơ đồ module đặt bàn không có saleStaff | Để NULL theo schema; không thêm trường người tiếp nhận vào form/model. |
| Customer6 trong ảnh module chỉ có rewardPoints/cardRank | PK Customer6 đồng thời FK Member6; đặt bàn cần customer id | Customer6 extends Member6, id và dữ liệu liên hệ kế thừa từ Member6 theo SQL. Customer6 chỉ khai báo thêm đúng rewardPoints/cardRank. |
| Hộp DAO6 lại ghi constructor `DAO()` | Java bắt buộc constructor trùng tên lớp | Dùng `DAO6()`. Không thể khai báo constructor DAO() trong lớp DAO6. |
| Dòng searchFreeTables trong ảnh ghi `DiningTable6` đơn, trong khi listTable/selectedTables và checkbox yêu cầu nhiều bàn | Luồng chọn bàn cần danh sách | Giữ đúng `DiningTable6 searchFreeTables(LocalDateTime arrivalTime, LocalDateTime EndTime)`, trả bàn đầu tiên hoặc null; lưu kết quả trong DAO và bổ sung getter `DiningTable6[] getListTable()` để JSP lấy đầy đủ danh sách sau truy vấn. Getter và thuộc tính nội bộ listTable là phần bổ sung tối thiểu cần đối chiếu. Không đổi kiểu trả về phương thức trong ảnh. |
| Trong ảnh chữ số 6 đứng sau nhãn JSP (`AddDish.jsp 6`, ...) | Tên file Java Web phải có phần mở rộng .jsp | Chuẩn hóa thành AddDish6.jsp và tương tự; suffix 6 ở trước .jsp. |
| Sơ đồ không thiết kế đăng nhập | Người dùng yêu cầu thêm đăng nhập/phân quyền | Thêm Login6.jsp, Member6 và MemberDAO6 trong đúng model/dao/view. Không thêm controller/service. |
| Wireframe danh sách món có cột Sửa, nhưng không có lớp/phương thức/trang sửa | Chỉ có getAllDishes/addDish | Giữ cột Sửa và nhãn mẫu; chưa có chức năng sửa, không tự thêm nút/phương thức update. |
| Wireframe ngày tìm bàn vẽ hộp xổ xuống | Sơ đồ ghi `inDate : date` | Dùng input type=date, đúng một trường ngày. |
| Sơ đồ ban đầu ghi `inTimeBlock : select` | Yêu cầu cập nhật: nhập start time và end time riêng | SearchTable6.jsp thay dropdown bằng `inStartTime` / `inEndTime`, tổng 4 trường và 1 nút. Giờ bắt đầu ánh xạ vào `arrivalTime`, giờ kết thúc vào `endTime`; giữ nguyên model, DAO và các cột SQL. |
| Wireframe ghi chú vẽ hộp một dòng | Sơ đồ ghi `inNote : textarea` | Giữ textarea gọn, đúng một trường. |

Không giả vờ rằng các khác biệt trên đã thống nhất trong tài liệu.

## Hợp đồng lớp

Các lớp model có constructor không tham số, getter/setter đơn giản; không đưa tính toán nghiệp vụ hay JDBC vào model.

| Lớp | Thuộc tính tự khai báo |
|---|---|
| Category6 | int id; String name; String description |
| Dish6 | int id; String name; Float price; String unit; String image; String description; Category6 category |
| DiningTable6 | int id; String name; int capacity; String location; String description |
| Customer6 | int rewardPoints; String cardRank |
| ReservationDetail6 | int id; DiningTable6 diningTable |
| TableReservation6 | int id; LocalDateTime createAt; LocalDateTime arrivalTime; LocalDateTime EndTime; int guestNumber; String contactName; String contactPhone; String contactEmail; String status; String note; Customer6 customer; ReservationDetail6[] reservationDetails |
| Member6 (bổ sung đăng nhập, theo SQL) | int id; String username; String password; String fullName; String address; String email; String phone; String role; String note |

| DAO | API |
|---|---|
| DAO6 | DAO6(); private Connection con; protected connection(); close() để đóng JDBC |
| DishDAO6 | DishDAO6(); Dish6[] getAllDishes(); boolean addDish(Dish6 dish) |
| CategoryDAO6 | CategoryDAO6(); Category6[] getAllCategories() |
| DiningTableDAO6 | DiningTableDAO6(); DiningTable6 searchFreeTables(LocalDateTime arrivalTime, LocalDateTime EndTime); getter bổ sung DiningTable6[] getListTable() như giải thích trên |
| TableReservationDAO6 | TableReservationDAO6(); boolean saveReservation(TableReservation6 reservation) |
| MemberDAO6 (bổ sung) | MemberDAO6(); Member6 authenticate(String username, String password) |

Phương thức setDiningTable có tham số `DiningTable6 diningTable`; setReservationDetails có tham số `ReservationDetail6[] details`. Tên/kiểu thuộc tính model giữ chữ hoa/thường theo ảnh. Throws SQLException và AutoCloseable phục vụ báo lỗi/đóng kết nối, không tạo lớp trung gian.

## Trang và số thành phần giao diện

| Trang | Trường nhập hiển thị | Nút | Thành phần khác |
|---|---|---|---|
| Login6.jsp (bổ sung) | username, password | 1: Đăng nhập | Không dropdown quyền/đăng ký |
| ManagerHome6.jsp | Không | 2: btnManageDish, btnLogout | Tiêu đề; Đăng xuất theo yêu cầu bổ sung |
| ManageDish6.jsp | Không | 1: btnAddDish | tblDish gồm id, tên, danh mục, đơn vị tính, ảnh, đơn giá, mô tả, sửa |
| AddDish6.jsp | slCategory, txtName, txtUnit, txtImage, txtDescription, txtPrice | 2: btnCancel, btnAdd | listCategory/dish6 là dữ liệu Java, không phải input mới |
| CustomerHome6.jsp | Không | 2: btnReserveTable, btnLogout | customer là dữ liệu session; Đăng xuất theo yêu cầu bổ sung |
| SearchTable6.jsp | inDate, inStartTime, inEndTime, inGuestNumber | 1: btnSearch | Tách giờ bắt đầu/kết thúc theo yêu cầu cập nhật; không thêm tìm theo vị trí/sức chứa |
| SelectTable6.jsp | chkTables: một checkbox mỗi bàn | 2: btnBack, btnContinue | tblTable đúng 5 cột: Chọn, Tên bàn, Sức chứa, Vị trí, Mô tả; thông tin ngày/khung giờ đúng wireframe |
| ConfirmReservation6.jsp | inName, inPhone, inEmail, inNote | 2: btnCancel, btnConfirm | outReservationInfo: ngày, giờ, số khách, bàn đã chọn, tổng sức chứa đúng wireframe |

ID của bàn chỉ nằm trong value của checkbox, không có cột ID phụ. arrivalTime/endTime/guestNumber/listTable/selectedTables là biến Java/session; không nhân thành các input trên trang chọn bàn. Token hidden CSRF không phải thuộc tính nghiệp vụ hiển thị.

[index.jsp](src/main/webapp/index.jsp) chỉ chuyển hướng tới đăng nhập. [Error6.jsp](src/main/webapp/view/Error6.jsp) chỉ hiển thị lỗi kỹ thuật; hai trang này không bổ sung trường hoặc nút nghiệp vụ.

## Quy tắc chưa được tài liệu quy định

- Tên món, danh mục, đơn vị tính, giá dương là bắt buộc; ảnh và mô tả tùy chọn. Giá dùng **Float** đúng sơ đồ/SQL FLOAT.
- Đặt bàn: ngày/giờ tương lai, số khách nguyên dương; tổng sức chứa >= số khách; họ tên và điện thoại bắt buộc, email và ghi chú tùy chọn.
- Giới hạn chiều dài lấy từ VARCHAR trong SQL. Ghi chú giới hạn 255 theo migration.
- Giờ bắt đầu/kết thúc do khách nhập đến phút, trong cùng ngày; giờ kết thúc phải sau giờ bắt đầu. Không giới hạn các khung 90 phút cố định.
- Ngày/giờ dùng Asia/Ho_Chi_Minh, DATETIME không chuyển đổi ngầm sang UTC.
- Bàn hoạt động có status AVAILABLE hoặc NULL; đặt bàn thành công status RESERVED; CANCELLED/CANCELED được bỏ qua khi kiểm tra trùng.
- Hai khoảng giao nhau khi `old.arrivalTime < new.endTime AND old.endTime > new.arrivalTime`; cho phép bàn được đặt nối tiếp ngay khi khoảng cũ kết thúc.
- DAO lưu đặt bàn và các chi tiết trong một transaction; khóa từng hàng bàn FOR UPDATE theo id tăng dần, kiểm tra lại lịch bằng locking read trước khi INSERT.
- Ảnh là URL http/https hoặc tài nguyên bên dưới đường dẫn ../assets/, không thêm upload file vào form.
- Phân quyền MANAGER/CUSTOMER lấy từ DB và kiểm tra thêm hàng trong tblManager6/tblCustomer6. Không nhận quyền từ request.
- Không có thiết kế đăng ký, sửa/xóa món, hủy đặt bàn, quản trị tài khoản; không thêm các giao diện này.

## Kiểm tra schema gốc

Đã đối chiếu database `restman` đang được cấu hình ngày 20/11/2026: đủ **23 bảng, 113 cột gốc, 23 khóa chính, 29 khóa ngoại**; tên cột/kiểu dữ liệu/nullable/AUTO_INCREMENT và toàn bộ PK/FK khớp file gốc. Database có thêm đúng cột `tblTableReservation6.note VARCHAR(255) NULL` từ migration (tổng 114 cột). MySQL Windows dùng `lower_case_table_names=1`, nên metadata lưu tên bảng chữ thường; câu SQL và file gốc vẫn giữ tên theo tài liệu.

Seed mở rộng lên **20 bàn** (thêm Bàn 03–20), sức chứa 2–10 người, chạy lại không tạo trùng. Truy vấn lịch thực tế xác nhận 20 bàn chưa có đặt chồng lấn cho từng ngày **20–27/11/2026** tại thời điểm kiểm tra. Bàn không có cột ngày trống; lịch trống được tính từ arrivalTime/endTime và các chi tiết đặt bàn. Không tạo đặt bàn giả, không xóa lịch đã có, không giới hạn ứng dụng chỉ được đặt đến 27/11.

SHA-256 của [restman6_schema.sql](restman6_schema.sql) trước và sau triển khai:

```text
FCB71FBEF717D9EEF1BBA1A711ADC699A678F9830B97E0356A2202A90DD92D9E
```

