package dao;

import model.Category6;
import java.sql.*;
import java.util.ArrayList;

public class CategoryDAO6 extends DAO6 {
    public CategoryDAO6() throws SQLException { super(); }

    public Category6[] getAllCategories() throws SQLException {
        ArrayList<Category6> list = new ArrayList<>();
        try (PreparedStatement ps = connection().prepareStatement(
                "SELECT id, name, description FROM tblCategory6 ORDER BY id");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Category6 category = new Category6();
                category.setId(rs.getInt("id"));
                category.setName(rs.getString("name"));
                category.setDescription(rs.getString("description"));
                list.add(category);
            }
        }
        return list.toArray(new Category6[0]);
    }
}

