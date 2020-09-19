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
  # https://mvnrepository.com/artifact/org.xerial/sqlite-jdbc
  # https://github.com/xerial/sqlite-jdbc/releases/tag/3.30.1
  # https://www.sqlite.org/download.html
  # https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.30.1/
  context 'SQLite' do
    context 'Basic test' do
      jdbc_prefix = 'sqlite'
      jdbc_path = '/usr/share/java'
      version = '3.8.7'
      version = '3.30.1'
      jars = ["sqlite-jdbc-#{version}.jar"]
      jdbc_driver_class_name = 'org.sqlite.JDBC'
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

        public class #{class_name} {

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
        1>/dev/null 2>/dev/null cd /tmp
        echo '#{source}' > '#{source_file}'
        javac -cp #{jars_cp}#{path_separator}. '#{source_file}'
        java -cp #{jars_cp}#{path_separator}. '#{class_name}'
      EOF
      ) do
          its(:exit_status) { should eq 0 }
          its(:stdout) { should match /Connected to product: SQLite/}
          its(:stdout) { should match /Table #{table_name} was created successfully/i }
          its(:stdout) { should match /rowid = 1/}
          its(:stderr) { should_not contain /exception|failure/i }
      end
    end
    context 'Blob test' do
      jdbc_prefix = 'sqlite'
      jdbc_path = '/usr/share/java'
      jdbc_driver_class_name = 'org.sqlite.JDBC'
      version = '3.8.7'
      version = '3.30.1'
      jars = ["sqlite-jdbc-#{version}.jar"]
      path_separator = ':'
      jars_cp = jars.collect{|jar| "#{jdbc_path}/#{jar}"}.join(path_separator)
      database_name = '/home/sergueik/.config/google-chrome/Default/Login Data'
      class_name = 'SQLiteJDBCBlobTest'
      source_file = "#{class_name}.java"

      source = <<-EOF

        import java.sql.Connection;
        import java.sql.DriverManager;
        import java.sql.PreparedStatement;
        import java.sql.ResultSet;
        import java.sql.SQLException;
        import java.sql.SQLFeatureNotSupportedException;
        import java.sql.Statement;
        import java.sql.Blob;

        public class #{class_name} {

          public static void main(String[] args) throws ClassNotFoundException {

            final String className = "#{jdbc_driver_class_name}";

            Class.forName(className);
            final String databaseName = "#{database_name}";
            String url = "jdbc:#{jdbc_prefix}:" + databaseName;

            Connection connection = null;
            connection = DriverManager.getConnection(url);
            Statement statement = connection.createStatement();
            statement.setQueryTimeout(30);
            ResultSet resultSet = statement
                .executeQuery("SELECT action_url, username_value, password_value FROM logins");
            while (resultSet.next()) {
              System.out.println("action_url = " + resultSet.getString("action_url") + "	" + " username_value = " + resultSet.getString("username_value"));
            // use getBytes to load BLOB column
            // https://github.com/xerial/sqlite-jdbc/blob/master/src/main/java/org/sqlite/jdbc3/JDBC3ResultSet.java#L249
            // https://www.sqlitetutorial.net/sqlite-java/jdbc-read-write-blob/


            FileOutputStream fos = null;
            // write binary stream into file
              cnt++;
              String filename = "/tmp/a" + cnt + ".txt";
              File file = new File(filename);
              try {
              fos = new FileOutputStream(file);

              System.out.println("Writing BLOB to file " + file.getAbsolutePath());
              InputStream input = resultSet.getBinaryStream("password_value");
              byte[] readBuffer = new byte[1024];
              byte[] keepBufer = null;

              int readCnt = 0;
              while ((readCnt =input.read(readBuffer)) > 0) {
                System.out.println("Read " +  readCnt + " bytes");
                // keepBufer = new byte[keepBufer.length + readBuffer.length];
                // System.arraycopy(readBuffer, 0, keepBufer, 0, readBuffer.length);
                fos.write( readBuffer, 0, readCnt);
                System.out.println("Trying to read more");
                  readCnt = input.read(readBuffer);
                System.out.println("Read " +  readCnt + " bytes");
              }
              } catch(IOException e) {
                System.out.println("Excption " + e.toString());
              }

              byte[] blob = resultSet.getBytes("password_value");
            // https://github.com/xerial/sqlite-jdbc/blob/master/src/main/java/org/sqlite/jdbc4/JDBC4ResultSet.java#L387
            /*
              public Blob getBlob(int col) throws SQLException { throw unused(); }
               protected SQLException unused() {
                 return new SQLFeatureNotSupportedException();
            }
            */
           int length = (int) blob.length ;
            System.out.println( "password_value = " + blob);
          }
        }
      EOF
      describe command(<<-EOF
        1>/dev/null 2>/dev/null cd /tmp
        echo '#{source}' > '#{source_file}'
        javac -cp #{jars_cp}#{path_separator}. '#{source_file}'
        java -cp #{jars_cp}#{path_separator}. '#{class_name}'
      EOF
      ) do
          its(:exit_status) { should eq 0 }
          its(:stderr) { should_not contain 'java.sql.SQLFeatureNotSupportedException' }
      end
    end
  end
end
