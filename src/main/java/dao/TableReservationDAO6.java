package dao;

import model.ReservationDetail6;
import model.TableReservation6;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.TreeSet;

public class TableReservationDAO6 extends DAO6 {
    public TableReservationDAO6() throws SQLException { super(); }

    public boolean saveReservation(TableReservation6 reservation) throws SQLException {
        if (reservation == null || reservation.getCustomer() == null
                || reservation.getArrivalTime() == null || reservation.getEndTime() == null
                || !reservation.getArrivalTime().isAfter(LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")))
                || !reservation.getArrivalTime().isBefore(reservation.getEndTime())
                || reservation.getGuestNumber() <= 0 || reservation.getReservationDetails() == null
                || reservation.getReservationDetails().length == 0) return false;
        TreeSet<Integer> ids = new TreeSet<>();
        for (ReservationDetail6 detail : reservation.getReservationDetails()) {
            if (detail == null || detail.getDiningTable() == null
                    || detail.getDiningTable().getId() <= 0 || !ids.add(detail.getDiningTable().getId()))
                return false;
        }
        Connection con = connection();
        boolean oldAutoCommit = con.getAutoCommit();
        con.setAutoCommit(false);
        try {
            long capacity = 0;
            // All requests lock table rows in the same order, including currently free tables.
            for (int id : ids) {
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT capacity,status FROM tblDiningTable6 WHERE id=? FOR UPDATE")) {
                    ps.setInt(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) { con.rollback(); return false; }
                        String status = rs.getString("status");
                        if ((status != null && !"AVAILABLE".equals(status)) || rs.getInt("capacity") <= 0) {
                            con.rollback(); return false;
                        }
                        capacity += rs.getInt("capacity");
                    }
                }
                // Locking read observes a booking committed while this transaction waited for a table lock.
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT r.id FROM tblTableReservation6 r JOIN tblReservationDetail6 d "
                        + "ON r.id=d.tblTableReservation6id WHERE d.tblDiningTable6id=? "
                        + "AND COALESCE(r.status,'') NOT IN ('CANCELLED','CANCELED') "
                        + "AND r.arrivalTime < ? AND r.endTime > ? FOR UPDATE")) {
                    ps.setInt(1, id);
                    ps.setTimestamp(2, Timestamp.valueOf(reservation.getEndTime()));
                    ps.setTimestamp(3, Timestamp.valueOf(reservation.getArrivalTime()));
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) { con.rollback(); return false; }
                    }
                }
            }
            if (capacity < reservation.getGuestNumber()) { con.rollback(); return false; }
            String sql = "INSERT INTO tblTableReservation6(createdAt,arrivalTime,endTime,guestNumber,"
                + "contactName,contactPhone,contactEmail,status,note,tblCustomer6id) VALUES(?,?,?,?,?,?,?,?,?,?)";
            LocalDateTime createAt = LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));
            int reservationId;
            try (PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setTimestamp(1, Timestamp.valueOf(createAt));
                ps.setTimestamp(2, Timestamp.valueOf(reservation.getArrivalTime()));
                ps.setTimestamp(3, Timestamp.valueOf(reservation.getEndTime()));
                ps.setInt(4, reservation.getGuestNumber());
                ps.setString(5, reservation.getContactName());
                ps.setString(6, reservation.getContactPhone());
                ps.setString(7, reservation.getContactEmail());
                ps.setString(8, "RESERVED");
                ps.setString(9, reservation.getNote());
                ps.setInt(10, reservation.getCustomer().getId());
                if (ps.executeUpdate() != 1) { con.rollback(); return false; }
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (!rs.next()) throw new SQLException("Missing reservation key");
                    reservationId = rs.getInt(1);
                }
            }
            int[] detailIds = new int[reservation.getReservationDetails().length];
            int index = 0;
            for (ReservationDetail6 detail : reservation.getReservationDetails()) {
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO tblReservationDetail6(tblTableReservation6id,tblDiningTable6id) VALUES(?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, reservationId);
                    ps.setInt(2, detail.getDiningTable().getId());
                    if (ps.executeUpdate() != 1) throw new SQLException("Missing reservation detail");
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) throw new SQLException("Missing detail key");
                        detailIds[index++] = rs.getInt(1);
                    }
                }
            }
            con.commit();
            reservation.setId(reservationId);
            reservation.setCreateAt(createAt);
            reservation.setStatus("RESERVED");
            for (int i = 0; i < detailIds.length; i++)
                reservation.getReservationDetails()[i].setId(detailIds[i]);
            return true;
        } catch (SQLException | RuntimeException ex) {
            con.rollback();
            throw ex;
        } finally {
            con.setAutoCommit(oldAutoCommit);
        }
    }
}

