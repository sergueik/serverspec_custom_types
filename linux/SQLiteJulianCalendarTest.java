import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.RowId;
import java.sql.Time;
import java.sql.Date;
import java.time.Instant;

public class SQLiteJulianCalendarTest {

	public static void main(String[] args) throws ClassNotFoundException {

		final String className = "org.sqlite.JDBC";

		Class.forName(className);
		final String databaseName = "_VARIABLES";
		String url = "jdbc:sqlite:" + databaseName;

		// in memory
		url = "jdbc:sqlite::memory:";

		final String tableName = "_VARIABLES";

		Connection connection = null;
		try {
			connection = DriverManager.getConnection(url);
			System.out.println("Connected to product: "
					+ connection.getMetaData().getDatabaseProductName() + "\t"
					+ "catalog: " + connection.getCatalog() + "\t" + "schema: "
					+ connection.getSchema());
			Statement statement = connection.createStatement();
			statement.setQueryTimeout(30);

			statement
					.executeUpdate(String.format("drop table if exists  %s;", tableName));
			statement.executeUpdate(String.format(
					"CREATE TEMP TABLE `%s`(date_end date, time_end time, date_start date, time_start time);",
					tableName));
			System.out.println(
					String.format("Table %s was created successfully", tableName));

			PreparedStatement preparedStatement = connection
					.prepareStatement(String.format(
							"INSERT INTO %s (date_end, time_end, date_start, time_start) VALUES (?, ?, ?, ?)",
							tableName));

			preparedStatement.setDate(1, Date.valueOf("2022-01-21"));
			preparedStatement.setTime(2, java.sql.Time.valueOf("19:57:00"));
			preparedStatement.setDate(3, Date.valueOf("2022-01-21"));
			preparedStatement.setTime(4, java.sql.Time.valueOf("06:57:00"));
			preparedStatement.execute();

			ResultSet resultSet = statement.executeQuery(String.format(
					"select date_end, date_start, time_end, time_start, STRFTIME(\"%%H:%%M:%%S\", julianday(datetime(date_end,  time_end )) - julianday(datetime(date_start,  time_start ))) as time_julian_delta, STRFTIME(\"%%H:%%M:%%S\",  CAST( strftime('%%s',datetime(date_end,  time_end ) )  AS LONG ) - CAST( strftime('%%s',datetime(date_start,  time_start ) ) AS LONG) )  as time_delta from `%s`;",
					tableName));
			while (resultSet.next()) {
				System.out.println(
						"time_delta = " + resultSet.getString(6 /* "time_delta" */));
				System.out.println("date_end = " + resultSet.getDate("date_end"));
				System.out.println("time_end = " + resultSet.getTime("time_end"));
				System.out.println("date_start = " + resultSet.getDate("date_start"));
				System.out.println("time_start = " + resultSet.getTime("time_start"));
			}
			resultSet.close();
		} catch (SQLException e) {
			System.err.println(e.getMessage());
		} finally {
			try {
				if (connection != null)
					connection.close();
			} catch (SQLException e) {
				System.err.println(e);
			}
		}
	}
}

