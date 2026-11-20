package dao;

import model.Member6;
import model.Customer6;
import java.sql.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/** Minimal authentication addition, because the two supplied diagrams omit login. */
public class MemberDAO6 extends DAO6 {
    public MemberDAO6() throws SQLException { super(); }

    public Member6 authenticate(String username, String password) throws SQLException {
        String sql = "SELECT m.*,c.rewardPoints,c.cardRank,c.id AS customerId,g.id AS managerId "
            + "FROM tblMember6 m LEFT JOIN tblCustomer6 c ON c.id=m.id "
            + "LEFT JOIN tblManager6 g ON g.id=m.id WHERE m.username=?";
        try (PreparedStatement ps = connection().prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next() || !matches(password, rs.getString("password"))) return null;
                Member6 member;
                if ("CUSTOMER".equals(rs.getString("role")) && rs.getObject("customerId") != null) {
                    Customer6 customer = new Customer6();
                    customer.setRewardPoints(rs.getInt("rewardPoints"));
                    customer.setCardRank(rs.getString("cardRank"));
                    member = customer;
                } else if ("MANAGER".equals(rs.getString("role")) && rs.getObject("managerId") != null) {
                    member = new Member6();
                } else return null;
                member.setId(rs.getInt("id"));
                member.setUsername(rs.getString("username"));
                member.setFullName(rs.getString("fullName"));
                member.setAddress(rs.getString("address"));
                member.setEmail(rs.getString("email"));
                member.setPhone(rs.getString("phone"));
                member.setRole(rs.getString("role"));
                member.setNote(rs.getString("note"));
                return member;
            }
        }
    }

    private boolean matches(String password, String stored) {
        if (password == null || stored == null) return false;
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(password.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : digest) hex.append(String.format("%02x", b & 255));
            return MessageDigest.isEqual(hex.toString().getBytes(StandardCharsets.US_ASCII),
                stored.getBytes(StandardCharsets.US_ASCII));
        } catch (NoSuchAlgorithmException ex) { throw new IllegalStateException(ex); }
    }
}

