# NOTE: this logic not correct under uru
if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

context 'JDBC tests' do

  # https://stackoverflow.com/questions/34817574/using-sqlite-in-android-to-get-rowid
  # https://www.sqlitetutorial.net/sqlite-autoincrement/
  # https://docs.oracle.com/javase/tutorial/jdbc/basics/sqlrowid.html
  # https://www.sqlitetutorial.net/sqlite-java/sqlite-jdbc-driver/
  context 'SQLite' do
    jdbc_prefix = 'sqlite'
    jdbc_path = '/usr/share/java'
    jdbc_driver_class_name = 'org.sqlite.JDBC'
    jars = ['sqlite-jdbc-3.8.7.jar']
    path_separator = ':'
    jars_cp = jars.collect{|jar| "#{jdbc_path}/#{jar}"}.join(path_separator)
    table_name = 'COMPANY'
    class_name = 'SQLiteJDBCTest'
    source_file = "#{class_name}.java"

    source = <<-EOF
    
    import java.sql.Connection;
      import java.sql.DriverManager;
      import java.sql.PreparedStatement;
      import java.sql.ResultSet;
      import java.sql.SQLException;
      import java.sql.Statement;
      import java.sql.RowId;

      public class SQLiteJDBCTest {

        public static void main(String[] args) throws ClassNotFoundException {

          final String className = "#{jdbc_driver_class_name}";

          Class.forName(className);
          final String databaseName = "#{table_name}";
          String url = "jdbc:#{jdbc_prefix}:" + databaseName;
            
          // in memory
          url = "jdbc:sqlite::memory:";

          final String tableName = "#{table_name}";

          Connection connection = null;
          try {
            connection = DriverManager.getConnection(url);
            System.out.println("Connected to product: "
                + connection.getMetaData().getDatabaseProductName() + "\\t"
                + "catalog: " + connection.getCatalog() + "\\t" + "schema: "
                + connection.getSchema());
            Statement statement = connection.createStatement();
            statement.setQueryTimeout(30);

            statement
                .executeUpdate(String.format("DROP TABLE IF EXISTS %s", tableName));
            statement.executeUpdate(String.format("CREATE TABLE %s"
                + "(ID INT PRIMARY KEY NOT NULL, NAME TEXT NOT NULL, AGE INT,"
                + "ADDRESS CHAR(50), SALARY REAL)", tableName));
            System.out.println(
                String.format("Table %s was created successfully", tableName));
            statement.executeUpdate(
                "INSERT INTO COMPANY (NAME, ID, AGE, SALARY) VALUES ('microsoft', 1, 1, 0.0)");
                // TODO: no such column: microsoft error from using shell to write the source
            PreparedStatement preparedStatement = connection.prepareStatement(
                "INSERT INTO COMPANY (NAME, ID, AGE) VALUES (?, ?, ?)");

            preparedStatement.setString(1, "redhat");
            preparedStatement.setInt(2, 2);
            preparedStatement.setInt(3, 42);
            preparedStatement.execute();
            ResultSet resultSet = statement
                .executeQuery("SELECT ROWID, NAME, ID FROM COMPANY");
            while (resultSet.next()) {
              System.out.println("rowid = " + resultSet.getString("ROWID") + "\\t"
                  + " name = " + resultSet.getString("NAME") + "\\t" + "id = "
                  + resultSet.getInt("ID"));
            }

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
    EOF
    describe command(<<-EOF
      1>/dev/null 2>/dev/null pushd /tmp
      echo '#{source}' > '#{source_file}'
      javac -cp #{jars_cp}#{path_separator}. '#{source_file}'
      java -cp #{jars_cp}#{path_separator}. '#{class_name}'
      1>/dev/null 2>/dev/null popd
    EOF
    ) do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should match /Connected to product: SQLite/}
        its(:stdout) { should match /Table #{table_name} was created successfully/i }
        its(:stdout) { should match /rowid = 1/}
        its(:stderr) { should_not contain /exception|failure/i }
    end
  end
end
