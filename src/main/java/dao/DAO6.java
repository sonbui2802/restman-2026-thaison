package dao;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/** JDBC connection only; no service/controller layer. */
public class DAO6 implements AutoCloseable {
    private Connection con;

    public DAO6() throws SQLException {
        try { Class.forName("com.mysql.cj.jdbc.Driver"); }
        catch (ClassNotFoundException ex) { throw new SQLException("MySQL Connector/J is missing", ex); }
        Properties config = new Properties();
        try (InputStream input = DAO6.class.getResourceAsStream("/db.properties")) {
            if (input == null) throw new SQLException("Missing src/main/resources/db.properties");
            config.load(new InputStreamReader(input, StandardCharsets.UTF_8));
        } catch (IOException ex) { throw new SQLException("Cannot read db.properties", ex); }
        for (String key : new String[]{"db.url", "db.username", "db.password"}) {
            if (!config.containsKey(key)) throw new SQLException("Missing configuration: " + key);
        }
        String url = System.getenv().getOrDefault("RESTMAN_DB_URL", config.getProperty("db.url"));
        con = DriverManager.getConnection(url,
            System.getenv().getOrDefault("RESTMAN_DB_USER", config.getProperty("db.username")),
            System.getenv().getOrDefault("RESTMAN_DB_PASSWORD", config.getProperty("db.password")));
    }

    protected Connection connection() { return con; }

    @Override
    public void close() throws SQLException { con.close(); }
}

