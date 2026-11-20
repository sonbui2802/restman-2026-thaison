package dao;

import model.DiningTable6;
import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;

public class DiningTableDAO6 extends DAO6 {
    private DiningTable6[] listTable = new DiningTable6[0];

    public DiningTableDAO6() throws SQLException { super(); }

    public DiningTable6 searchFreeTables(LocalDateTime arrivalTime, LocalDateTime EndTime) throws SQLException {
        listTable = new DiningTable6[0];
        if (arrivalTime == null || EndTime == null || !arrivalTime.isBefore(EndTime)) return null;
        String sql = "SELECT t.id,t.name,t.capacity,t.location,t.description FROM tblDiningTable6 t "
            + "WHERE (t.status IS NULL OR t.status='AVAILABLE') AND t.capacity>0 AND NOT EXISTS ("
            + "SELECT 1 FROM tblReservationDetail6 d JOIN tblTableReservation6 r ON r.id=d.tblTableReservation6id "
            + "WHERE d.tblDiningTable6id=t.id AND COALESCE(r.status,'') NOT IN ('CANCELLED','CANCELED') "
            + "AND r.arrivalTime < ? AND r.endTime > ?) ORDER BY t.id";
        ArrayList<DiningTable6> list = new ArrayList<>();
        try (PreparedStatement ps = connection().prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(EndTime));
            ps.setTimestamp(2, Timestamp.valueOf(arrivalTime));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    DiningTable6 table = new DiningTable6();
                    table.setId(rs.getInt("id"));
                    table.setName(rs.getString("name"));
                    table.setCapacity(rs.getInt("capacity"));
                    table.setLocation(rs.getString("location"));
                    table.setDescription(rs.getString("description"));
                    list.add(table);
                }
            }
        }
        listTable = list.toArray(new DiningTable6[0]);
        return listTable.length == 0 ? null : listTable[0];
    }

    /** The diagram returns one table; the selection view also needs the complete result. */
    public DiningTable6[] getListTable() { return listTable.clone(); }
}

