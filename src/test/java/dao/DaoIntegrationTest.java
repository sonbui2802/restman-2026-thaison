package dao;

import model.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import java.sql.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;

/** Real MySQL integration checks, enabled only against a separate restman_test6 schema. */
@EnabledIfEnvironmentVariable(named="RESTMAN_INTEGRATION_TESTS", matches="true")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class DaoIntegrationTest {
    private Connection admin;
    private int customerId, categoryId;
    private int[] tables = new int[2];
    private final String marker = "test6-" + UUID.randomUUID();
    private final LocalDateTime base = LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(60).atTime(10,0);

    @BeforeAll
    void fixtures() throws Exception {
        String url = System.getenv("RESTMAN_DB_URL");
        assertNotNull(url);
        assertTrue(url.matches("jdbc:mysql://[^/]+/restman_test6\\?.*"),
            "Integration tests require a separate restman_test6 database.");
        admin = DriverManager.getConnection(url, System.getenv("RESTMAN_DB_USER"), System.getenv("RESTMAN_DB_PASSWORD"));
        int memberId = insert("INSERT INTO tblMember6(username,password,fullName,role) VALUES(?,SHA2('12345678',256),'Test','CUSTOMER')", marker);
        customerId = memberId;
        execute("INSERT INTO tblCustomer6(id,rewardPoints,cardRank) VALUES(?,0,'STANDARD')", customerId);
        categoryId=insert("INSERT INTO tblCategory6(name) VALUES(?)",marker);
        for (int i=0;i<2;i++) tables[i]=insert("INSERT INTO tblDiningTable6(name,capacity,status) VALUES(?,4,'AVAILABLE')",marker+"-"+i);
    }

    @AfterAll
    void cleanup() throws Exception {
        if (admin==null) return;
        try {
            execute("DELETE d FROM tblReservationDetail6 d JOIN tblTableReservation6 r ON r.id=d.tblTableReservation6id WHERE r.tblCustomer6id=?",customerId);
            execute("DELETE FROM tblTableReservation6 WHERE tblCustomer6id=?",customerId);
            for (int id:tables) execute("DELETE FROM tblDiningTable6 WHERE id=?",id);
            execute("DELETE FROM tblDish6 WHERE tblCategory6id=?",categoryId);
            execute("DELETE FROM tblCategory6 WHERE id=?",categoryId);
            execute("DELETE FROM tblCustomer6 WHERE id=?",customerId);
            execute("DELETE FROM tblMember6 WHERE id=?",customerId);
        } finally { admin.close(); }
    }

    @Test void loginChecksPasswordRoleAndSqlInjection() throws Exception {
        try (MemberDAO6 dao=new MemberDAO6()) {
            assertInstanceOf(Customer6.class,dao.authenticate(marker,"12345678"));
            assertNull(dao.authenticate(marker,"wrong"));
            assertNull(dao.authenticate("' OR 1=1 -- ","12345678"));
            assertEquals("MANAGER",dao.authenticate("managerson","12345678").getRole());
        }
    }

    @Test void addDishPreservesUnicodeAndPreparedValues() throws Exception {
        Dish6 dish=new Dish6(); Category6 category=new Category6(); category.setId(categoryId);
        dish.setCategory(category); dish.setName("Cá ' <script> sốt me"); dish.setPrice(125000f);
        dish.setUnit("Đĩa"); dish.setImage(""); dish.setDescription("Mô tả");
        try (DishDAO6 dao=new DishDAO6()) {
            assertTrue(dao.addDish(dish)); assertTrue(dish.getId()>0);
            assertTrue(Arrays.stream(dao.getAllDishes()).anyMatch(d->d.getId()==dish.getId() && dish.getName().equals(d.getName())));
        }
    }

    @Test void rejectNonFiniteAndNegativePrice() throws Exception {
        Dish6 dish=new Dish6(); Category6 category=new Category6(); category.setId(categoryId);
        dish.setCategory(category); dish.setName(marker);
        try (DishDAO6 dao=new DishDAO6()) {
            dish.setPrice(Float.NaN); assertFalse(dao.addDish(dish));
            dish.setPrice(Float.POSITIVE_INFINITY); assertFalse(dao.addDish(dish));
            dish.setPrice(-1f); assertFalse(dao.addDish(dish));
        }
    }

    @Test void multiTableBookingAndNotePersistAtomically() throws Exception {
        TableReservation6 reservation=booking(base.plusDays(1),7,tables[0],tables[1]);
        reservation.setNote("Gần cửa sổ — khách Việt");
        try (TableReservationDAO6 dao=new TableReservationDAO6()) { assertTrue(dao.saveReservation(reservation)); }
        try (PreparedStatement ps=admin.prepareStatement("SELECT note,(SELECT COUNT(*) FROM tblReservationDetail6 WHERE tblTableReservation6id=r.id) AS n FROM tblTableReservation6 r WHERE id=?")) {
            ps.setInt(1,reservation.getId());
            try (ResultSet rs=ps.executeQuery()) { assertTrue(rs.next()); assertEquals(reservation.getNote(),rs.getString("note")); assertEquals(2,rs.getInt("n")); }
        }
        assertNotNull(reservation.getCreateAt());
        assertTrue(reservation.getReservationDetails()[0].getId()>0);
    }

    @Test void overlapBlockedAndAdjacentSlotAllowed() throws Exception {
        LocalDateTime start=base.plusDays(2);
        try (TableReservationDAO6 dao=new TableReservationDAO6()) {
            assertTrue(dao.saveReservation(booking(start,2,tables[0])));
            assertFalse(dao.saveReservation(booking(start.plusMinutes(30),2,tables[0])));
            assertTrue(dao.saveReservation(booking(start.plusMinutes(90),2,tables[0])));
        }
        try (DiningTableDAO6 dao=new DiningTableDAO6()) {
            dao.searchFreeTables(start,start.plusMinutes(90));
            assertFalse(Arrays.stream(dao.getListTable()).anyMatch(t->t.getId()==tables[0]));
            DiningTable6 first=dao.searchFreeTables(start.plusHours(3),start.plusHours(4));
            assertNotNull(first);
            assertTrue(Arrays.stream(dao.getListTable()).anyMatch(t->t.getId()==tables[0]));
        }
    }

    @Test void insufficientCapacityAndDuplicateTablesLeaveNoRows() throws Exception {
        int count=countReservations();
        try (TableReservationDAO6 dao=new TableReservationDAO6()) {
            assertFalse(dao.saveReservation(booking(base.plusDays(3),5,tables[0])));
            assertFalse(dao.saveReservation(booking(base.plusDays(3),2,tables[0],tables[0])));
            assertFalse(dao.saveReservation(booking(base.minusYears(1),2,tables[0])));
        }
        assertEquals(count,countReservations());
    }

    @Test void invalidCustomerRollsBackReservationAndDetails() throws Exception {
        int count=countReservations();
        TableReservation6 reservation=booking(base.plusDays(4),2,tables[0]);
        Customer6 invalid=new Customer6(); invalid.setId(Integer.MAX_VALUE); reservation.setCustomer(invalid);
        try (TableReservationDAO6 dao=new TableReservationDAO6()) { assertThrows(SQLException.class,()->dao.saveReservation(reservation)); }
        assertEquals(count,countReservations());
        reservation.setCustomer(customer());
        try (TableReservationDAO6 dao=new TableReservationDAO6()) { assertTrue(dao.saveReservation(reservation)); }
    }

    @Test void twoConcurrentRequestsHaveExactlyOneWinner() throws Exception {
        ExecutorService pool=Executors.newFixedThreadPool(2);
        CountDownLatch ready=new CountDownLatch(2), start=new CountDownLatch(1);
        Callable<Boolean> attempt=()->{
            try (TableReservationDAO6 dao=new TableReservationDAO6()) {
                ready.countDown(); assertTrue(start.await(10,TimeUnit.SECONDS));
                return dao.saveReservation(booking(base.plusDays(5),2,tables[1]));
            }
        };
        try {
            Future<Boolean> first=pool.submit(attempt), second=pool.submit(attempt);
            assertTrue(ready.await(10,TimeUnit.SECONDS)); start.countDown();
            int successes=(first.get(20,TimeUnit.SECONDS)?1:0)+(second.get(20,TimeUnit.SECONDS)?1:0);
            assertEquals(1,successes);
        } finally { start.countDown(); pool.shutdownNow(); }
    }

    private Customer6 customer() { Customer6 c=new Customer6(); c.setId(customerId); return c; }
    private TableReservation6 booking(LocalDateTime start,int guests,int... ids) {
        TableReservation6 r=new TableReservation6(); r.setArrivalTime(start); r.setEndTime(start.plusMinutes(90));
        r.setGuestNumber(guests); r.setContactName("Khách kiểm thử"); r.setContactPhone("0901234567");
        r.setContactEmail("test@example.com"); r.setCustomer(customer());
        ReservationDetail6[] details=new ReservationDetail6[ids.length];
        for(int i=0;i<ids.length;i++) { DiningTable6 t=new DiningTable6(); t.setId(ids[i]); details[i]=new ReservationDetail6(); details[i].setDiningTable(t); }
        r.setReservationDetails(details); return r;
    }
    private int countReservations() throws SQLException {
        try (PreparedStatement ps=admin.prepareStatement("SELECT COUNT(*) FROM tblTableReservation6 WHERE tblCustomer6id=?")) {
            ps.setInt(1,customerId); try(ResultSet rs=ps.executeQuery()) { rs.next(); return rs.getInt(1); }
        }
    }
    private int insert(String sql,Object... args) throws SQLException {
        try(PreparedStatement ps=admin.prepareStatement(sql,Statement.RETURN_GENERATED_KEYS)) {
            for(int i=0;i<args.length;i++) ps.setObject(i+1,args[i]); ps.executeUpdate();
            try(ResultSet rs=ps.getGeneratedKeys()) { rs.next(); return rs.getInt(1); }
        }
    }
    private void execute(String sql,Object... args) throws SQLException {
        try(PreparedStatement ps=admin.prepareStatement(sql)) {
            for(int i=0;i<args.length;i++) ps.setObject(i+1,args[i]); ps.executeUpdate();
        }
    }
}

