package dao;

import model.Category6;
import model.Dish6;
import java.sql.*;
import java.util.ArrayList;

public class DishDAO6 extends DAO6 {
    public DishDAO6() throws SQLException { super(); }

    public Dish6[] getAllDishes() throws SQLException {
        ArrayList<Dish6> list = new ArrayList<>();
        String sql = "SELECT d.id,d.name,d.price,d.unit,d.image,d.description,"
            + "c.id AS categoryId,c.name AS categoryName,c.description AS categoryDescription "
            + "FROM tblDish6 d LEFT JOIN tblCategory6 c ON d.tblCategory6id=c.id ORDER BY d.id";
        try (PreparedStatement ps = connection().prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Dish6 dish = new Dish6();
                dish.setId(rs.getInt("id"));
                dish.setName(rs.getString("name"));
                Float price = rs.getObject("price", Float.class);
                dish.setPrice(price);
                dish.setUnit(rs.getString("unit"));
                dish.setImage(rs.getString("image"));
                dish.setDescription(rs.getString("description"));
                if (rs.getObject("categoryId") != null) {
                    Category6 category = new Category6();
                    category.setId(rs.getInt("categoryId"));
                    category.setName(rs.getString("categoryName"));
                    category.setDescription(rs.getString("categoryDescription"));
                    dish.setCategory(category);
                }
                list.add(dish);
            }
        }
        return list.toArray(new Dish6[0]);
    }

    public boolean addDish(Dish6 dish) throws SQLException {
        if (dish == null || dish.getCategory() == null || dish.getName() == null
                || dish.getName().isBlank() || dish.getPrice() == null
                || !Float.isFinite(dish.getPrice()) || dish.getPrice() <= 0) return false;
        String sql = "INSERT INTO tblDish6(name,price,unit,image,description,tblCategory6id) VALUES(?,?,?,?,?,?)";
        try (PreparedStatement ps = connection().prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, dish.getName());
            ps.setFloat(2, dish.getPrice());
            ps.setString(3, dish.getUnit());
            ps.setString(4, dish.getImage());
            ps.setString(5, dish.getDescription());
            ps.setInt(6, dish.getCategory().getId());
            if (ps.executeUpdate() != 1) return false;
            try (ResultSet rs = ps.getGeneratedKeys()) { if (rs.next()) dish.setId(rs.getInt(1)); }
            return true;
        }
    }
}

