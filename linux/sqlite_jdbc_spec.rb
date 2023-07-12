# NOTE: this logic not correct under uru
# Copyright (c) Serguei Kouzmine
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
  # https://github.com/xerial/sqlite-jdbc/releases/tag/3.28.0
  # https://www.sqlite.org/download.html
  # https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.28.0/
  context 'SQLite' do
    context 'Basic test' do
      jdbc_prefix = 'sqlite'
      jdbc_path = '/usr/share/java'
      version = '3.28.0'
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
              statement.executeUpdate(String.format("CREATE TABLE `%s`"
                  + "(`ID` INT PRIMARY KEY NOT NULL, `NAME` TEXT NOT NULL, AGE INT,"
                  + "ADDRESS CHAR(50), SALARY REAL)", tableName));
              System.out.println(
                  String.format("Table %s was created successfully", tableName));
              PreparedStatement preparedStatement = connection.prepareStatement(
                  String.format("INSERT INTO %s (NAME, ID, AGE) VALUES (?, ?, ?)", tableName));

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
    # temporarily disabled : expects the chrome profile ofspecific user
    context 'Blob test' , :if => false do

      jdbc_prefix = 'sqlite'
      jdbc_path = '/usr/share/java'
      jdbc_driver_class_name = 'org.sqlite.JDBC'
      version = '3.28.0'
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
              resultSet.close();
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
                System.out.println("Exception " + e.toString());
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
    context 'CachedRowSet - Java JDBC' do
    # http://www.java2s.com/example/java/jdbc/retrieving-data-using-a-cachedrowset.html
    #
      jdbc_prefix = 'sqlite'
      jdbc_path = '/usr/share/java'
      jdbc_driver_class_name = 'org.sqlite.JDBC'
      version = '3.28.0'
      jars = ["sqlite-jdbc-#{version}.jar"]
      path_separator = ':'
      jars_cp = jars.collect{|jar| "#{jdbc_path}/#{jar}"}.join(path_separator)
      class_name = 'SQLiteJDBCCachedRowSetTest'
      table_name = 'COMPANY'
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
        import javax.sql.rowset.RowSetFactory;
        import javax.sql.rowset.RowSetProvider;
        import javax.sql.rowset.CachedRowSet;
        import java.io.FileInputStream;
        import java.io.FileOutputStream;
        import java.io.ObjectInputStream;
        import java.io.ObjectOutputStream;

        import javax.sql.rowset.CachedRowSet;

        public class #{class_name} {
            final static String tableName = "#{table_name}";
          public static void main(String[] args) throws ClassNotFoundException, SQLException,InterruptedException {

            final String className = "#{jdbc_driver_class_name}";

            Class.forName(className);

            // in memory
            String url = "jdbc:sqlite::memory:";

              Connection connection = DriverManager.getConnection(url);
              Statement statement = connection.createStatement();
              statement.setQueryTimeout(30);

              statement
                  .executeUpdate(String.format("DROP TABLE IF EXISTS %s", tableName));
              statement.executeUpdate(String.format("CREATE TABLE `%s`"
                  + "(`ID` INT PRIMARY KEY NOT NULL, `NAME` TEXT NOT NULL, AGE INT,"
                  + "ADDRESS CHAR(50), SALARY REAL)", tableName));
              System.out.println(
                  String.format("Table %s was created successfully", tableName));
              PreparedStatement preparedStatement = connection.prepareStatement(
                  String.format("INSERT INTO %s (NAME, ID, AGE) VALUES (?, ?, ?)", tableName));

              preparedStatement.setString(1, "redhat");
              preparedStatement.setInt(2, 2);
              preparedStatement.setInt(3, 42);
              // Exception org.sqlite.SQLiteException: [SQLITE_ERROR] SQL error or missing database (no such table: COMPANY)
              // preparedStatement.executeUpdate();
              preparedStatement.execute();

            OrderComponent comp = new OrderComponent();
            
            try(CachedRowSet rowSet1 = comp.ordersByStatus();
            FileOutputStream fout = new FileOutputStream("row_set_serialized.ser");
            ObjectOutputStream oos = new ObjectOutputStream(fout);){
            
            oos.writeObject(rowSet1);
            fout.close();
            oos.close();
            
            // Read CachedRowSet from file
            try(FileInputStream fin = new FileInputStream("row_set_serialized.ser");
              ObjectInputStream ois = new ObjectInputStream(fin);
              CachedRowSet rowSet2 = (CachedRowSet)ois.readObject();){
              
              // Print out CachedRowSet
              while (rowSet2.next()) {
                System.out.println("rowid = " + rowSet2.getString("ROWID") + "\\t"
                    + " name = " + rowSet2.getString("NAME") + "\\t" + "id = "
                    + rowSet2.getInt("ID"));
              }
              
            }} catch (Exception e) {
                System.out.println("Exception " + e.toString());

            }
          }
        public static class OrderComponent {

            final String tableName = "#{table_name}";

          public CachedRowSet ordersByStatus() throws Exception {

            String queryString = "SELECT ROWID, NAME, ID FROM " + tableName;
            // using globs is OK
            // String queryString = "SELECT * FROM " + tableName;
            RowSetFactory rowSetProvider = RowSetProvider.newFactory();
            CachedRowSet rowSet = rowSetProvider.createCachedRowSet();
            
            // in memory
            String url = "jdbc:sqlite::memory:";
            rowSet.setUrl(url);

            rowSet.setCommand(queryString);            
            // rowSet.setString(1, status);            
            rowSet.execute();
            return rowSet;
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
          its(:stderr) { should_not contain 'java.sql.SQLFeatureNotSupportedException' }
          its(:stdout) { should match /name: redhat/}
      end
    end
  end
end

