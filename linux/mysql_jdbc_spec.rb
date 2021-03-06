# NOTE: this logic not correct under uru
if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'


context 'JDBC tests' do
  # yum install -qy mariadb-server
  # yum install -qy mysql-connector-java.noarch
  # rpm -ql $(rpm -qa |  grep mysql-connector-java)
  # systemctl start mariadb ; systemctl enable mariadb
  # https://linuxize.com/post/install-mariadb-on-centos-7/
  # https://support.rackspace.com/how-to/mysql-resetting-a-lost-mysql-root-password/
  jdbc_prefix = 'mysql'
  jdbc_path = '/usr/share/java'
  # jar tvf /usr/share/java/mysql-connector-java.jar |  grep Driver.class
  #  com/mysql/jdbc/Driver.class
  #  org/gjt/mm/mysql/Driver.class

  # jdbc_driver_class_name = 'com.microsoft.sqlserver.jdbc.SQLServerDriver'
  jdbc_driver_class_name = 'org.gjt.mm.mysql.Driver'
  jars = ['mysql-connector-java.jar'] # installed by yum
  path_separator = ':'
  jars_cp = jars.collect{|jar| "#{jdbc_path}/#{jar}"}.join(path_separator)
  database_host = 'localhost'
  options = 'useUnicode=true'
  # unable to set password access in information_schema:
  # ERROR 1109 (42S02): Unknown table 'user' in information_schema
  database_name = 'mysql'
  username = 'root'
  # Will exercise attempt to connect on JDBC without password:
  # experiencing challenges setting one on Centos / MariaDB
  password =  ''

  context 'Connection check', :if => false do
    class_name = 'MySQLJDBCNoPasswordTest'
    database2 = 'mysql'
    database_name = database2
    source_file = "#{class_name}.java"

    source = <<-EOF
      import java.sql.Connection;
      import java.sql.DriverManager;

      public class #{class_name} {
        public static void main(String[] argv) throws Exception {
         String className = "#{jdbc_driver_class_name}";
         try {
            Class driverObject = Class.forName(className);
            System.out.println("driverObject=" + driverObject);

            final String serverName = "#{database_host}";
            final String databaseName = "#{database_name}";
            final String options = "#{options}";
            // Exception: Communications link failure
            // final String url = "jdbc:#{jdbc_prefix}://" + serverName + "/" + databaseName + "?" + options;
            final String url = "jdbc:#{jdbc_prefix}://" + serverName + "/" + databaseName;
            final String username = "#{username}";
            final String password = "#{password}";
            // when password is blank JDBC will attempt to connect without using password.
            // as opposed to calling the DriverManager.getConnection with just url which fails.
            Connection connection = DriverManager.getConnection(url, username, "");
            if (connection != null) {
              System.out.println("Connected to product: " + connection.getMetaData().getDatabaseProductName());
              System.out.println("Connected to catalog: " + connection.getCatalog());
              // System.out.println("Connected to: " + connection.getSchema());
              // java.sql.SQLFeatureNotSupportedException: Not supported
            } else {
              System.out.println("Failed to connect");
            }
          } catch (Exception e) {
            System.out.println("Exception: " + e.getMessage());
            e.printStackTrace();
          }
        }
      }

    EOF
    describe command(<<-EOF
      1>/dev/null 2>/dev/null pushd /tmp
      echo '#{source}' > '#{source_file}'
      javac '#{source_file}'
      java -cp #{jars_cp}#{path_separator}. '#{class_name}'
      1>/dev/null 2>/dev/null popd
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /Connected to product: MySQL/}
      its(:stdout) { should match /Connected to catalog: #{database2}/}
      its(:stderr) { should_not contain 'Exception: Communications link failure' } # mysql server is not running
      its(:stderr) { should_not contain 'Exception: Access denied for user' } # configuration mismatch
      its(:stderr) { should_not contain 'Not supported' }
    end
  end
  # session variables do not work through JDBC..
  # http://www.sqlines.com/mysql/session_variables
  # https://stackoverflow.com/questions/10797794/multiple-queries-executed-in-java-in-single-statement/28142845
  # https://www.roseindia.net/jsp/mysql-allowMultiQueries-example.shtml
  context 'Assert', :if => false do
    class_name = 'MySQLJDBCAssertTest'
    database_name = 'information_schema'
    options = 'allowMultiQueries=true&autoReconnect=true&useUnicode=true&characterEncoding=UTF-8'
    source_file = "#{class_name}.java"

    source_data = <<-EOF
      import java.sql.Connection;
      import java.sql.DriverManager;
      import java.sql.ResultSet;
      import java.sql.Statement;
      import java.sql.PreparedStatement;
      import java.sql.CallableStatement;

      public class #{class_name} {
        public static void main(String[] argv) throws Exception {
          String className = "#{jdbc_driver_class_name}";
          try {
            Class driverObject = Class.forName(className);
            System.out.println("driverObject=" + driverObject);

            final String serverName = "#{database_host}";
            final String databaseName = "#{database_name}";
            final String options = "#{options}";
            // Exception: Communications link failure
            final String url = "jdbc:#{jdbc_prefix}://" + serverName + "/" +
            databaseName + "?" + options;
            final String username = "#{username}";
            final String password = "#{password}";
            // when password is blank JDBC will attempt to connect without using
            // password.
            // as opposed to calling the DriverManager.getConnection with just url
            // which fails.
            Connection connection = DriverManager.getConnection(url, username, "");

            if (connection != null) {
              System.out.println("Connected to product: "
                  + connection.getMetaData().getDatabaseProductName());
              System.out.println("Connected to catalog: " + connection.getCatalog());
              Statement statement = connection.createStatement(
                  ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);

              // NOTE: minor problems with single quotes
              String query = "SELECT character_set_name as name from character_sets limit 1 INTO @variable; SELECT @variable;";

              PreparedStatement preparedStatement = connection.prepareStatement(query);
      
              preparedStatement.execute();
              ResultSet resultSet = preparedStatement.getResultSet();
              // query = "SELECT character_set_name as name from character_sets limit 1";
              // ResultSet resultSet = statement.executeQuery(query);
              // https://docs.oracle.com/javase/tutorial/jdbc/basics/retrieving.html#rs_interface
		// https://docs.oracle.com/javase/7/docs/api/java/sql/ResultSet.html
              // alternatively just
              resultSet.first();
              String name = resultSet.getString(1);
              System.out.println("character set: " + name);
              // String description = resultSet.getString(2);
              // System.out.println("description: " + description);

              // https://alvinalexander.com/blog/post/jdbc/program-search-for-given-field-name-in-all-database-tables-in-d/

              resultSet.close();
              statement.close();
              connection.close();
            } else {
              System.out.println("Failed to connect");
            }
          } catch (Exception e) {
            System.out.println("Exception: " + e.getMessage());
            e.printStackTrace();
          }
        }
      }

    EOF
    before(:each) do
      $stderr.puts "Writing #{source_file}"
      Dir.chdir '/tmp'
      file = File.open(source_file, 'w')
      file.puts source_data.strip
      file.close
    end
    describe command(<<-EOF
      1>/dev/null 2>/dev/null pushd /tmp
      javac '#{source_file}'
      java -cp #{jars_cp}#{path_separator}. '#{class_name}'
      1>/dev/null 2>/dev/null popd
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should_not match /character set: utf8/}
      its(:stderr) { should be_empty }
    end
  end
  context 'Multi Queries' do
    class_name = 'MySQLJDBCMultiQueriesTest'
    database_name = 'information_schema'
    options = 'allowMultiQueries=true&autoReconnect=true&useUnicode=true&characterEncoding=UTF-8'
    source_file = "#{class_name}.java"

    source_data = <<-EOF
      import java.sql.Connection;
      import java.sql.DriverManager;
      import java.sql.ResultSet;
      import java.sql.Statement;
      import java.sql.PreparedStatement;
      import java.sql.CallableStatement;

      public class #{class_name} {
        public static void main(String[] argv) throws Exception {
          String className = "#{jdbc_driver_class_name}";
          try {
            Class driverObject = Class.forName(className);
            System.out.println("driverObject=" + driverObject);

            final String serverName = "#{database_host}";
            final String databaseName = "#{database_name}";
            final String options = "#{options}";
            // Exception: Communications link failure
            final String url = "jdbc:#{jdbc_prefix}://" + serverName + "/" +
            databaseName + "?" + options;
            final String username = "#{username}";
            final String password = "#{password}";
            Connection connection = DriverManager.getConnection(url, username, password);
      
            if (connection != null) {
              System.out.println("Connected to product: " + connection.getMetaData().getDatabaseProductName());
              System.out.println("Connected to catalog: " + connection.getCatalog());
      
              // WARNING: On both MySQL 5.7 and MYSQL 8.x JDBC appears broken:
              // when combine SQL statements only the first one gets executed
              // the second and following are ignored
              // below, even the field list is different
              String query = "SELECT character_set_name, description from character_sets where character_set_name like 'utf16%' limit 1;"
                  + "SELECT character_set_name from character_sets where description not like '%unicode%';" 
                  + "SELECT character_set_name from character_sets where character_set_name like 'utf8%' limit 1;";
              System.out.println("Executing combined query: " + query);
      
              PreparedStatement preparedStatement = connection.prepareStatement(query);
      
              preparedStatement.execute();
              ResultSet resultSet = preparedStatement.getResultSet();
              while (resultSet.next()) {
                String name = resultSet.getString(1);
                String description = resultSet.getString(2);
                System.out.println("character set: " + name);
                System.out.println("description: " + description);
              }
              resultSet.close();
              preparedStatement.close();
              connection.close();
            } else {
              System.out.println("Failed to connect");
            }
          } catch (Exception e) {
            // java.sql.SQLNonTransientConnectionException:
            System.out.println("Exception: " + e.getMessage());
            e.printStackTrace();
          }
        }
      }
    EOF
    before(:each) do
      $stderr.puts "Writing #{source_file}"
      Dir.chdir '/tmp'
      file = File.open(source_file, 'w')
      file.puts source_data.strip
      file.close
    end
    describe command(<<-EOF
      1>/dev/null 2>/dev/null pushd /tmp
      javac '#{source_file}'
      java -cp #{jars_cp}#{path_separator}. '#{class_name}'
      1>/dev/null 2>/dev/null popd
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /character set: utf16/}
      its(:stdout) { should_not match /character set: utf8/}
      its(:stderr) { should be_empty }
    end
  end
  context 'Stored Procedure' do
  #  DELIMITER //
  #  CREATE PROCEDURE simpleproc (OUT param1 INT) BEGIN SELECT 42 INTO param1 FROM dual; end//
  #  DELIMETER ;
    class_name = 'MySQLJDBCStoredProcedureTest'
    database_name = 'test'
    options = 'allowMultiQueries=true&autoReconnect=true&useUnicode=true&characterEncoding=UTF-8'
    source_file = "#{class_name}.java"

    source_data = <<-EOF
      import java.sql.Connection;
      import java.sql.DriverManager;
      import java.sql.ResultSet;
      import java.sql.Statement;
      import java.sql.CallableStatement;
      import java.sql.PreparedStatement;

      public class #{class_name} {
        public static void main(String[] argv) throws Exception {
          String className = "#{jdbc_driver_class_name}";
          try {
            Class driverObject = Class.forName(className);

            final String serverName = "#{database_host}";
            final String databaseName = "#{database_name}";
            final String options = "#{options}";
            // Exception: Communications link failure
            final String url = "jdbc:#{jdbc_prefix}://" + serverName + "/" +
            databaseName + "?" + options;
            final String username = "#{username}";
            final String password = "#{password}";
            Connection connection = DriverManager.getConnection(url, username, password);
      
            if (connection != null) {
              // http://www.java2s.com/Tutorials/Java/JDBC/0050__JDBC_CallableStatement.htm
              // http://www.java2s.com/Code/JavaAPI/java.sql/CallableStatementexecute.htm
              CallableStatement callableStatement = connection.prepareCall("{call simpleproc(?)}");
              // cstmt.setInt(1, 100);
              // https://docs.oracle.com/javase/8/docs/api/java/sql/Types.html
              // callableStatement.registerOutParameter(1, java.sql.Types.VARCHAR);
              callableStatement.registerOutParameter(1, java.sql.Types.INTEGER);
              callableStatement.execute();
              int number = callableStatement.getInt(1);
              System.out.println("Statement returns: "  + number);
              connection.close();
            } else {
              System.err.println("Failed to connect");
            }
          } catch (Exception e) {
            // java.sql.SQLNonTransientConnectionException:
            System.err.println("Exception: " + e.getMessage());
            e.printStackTrace();
          }
        }
      }
    EOF
    before(:each) do
      $stderr.puts "Writing #{source_file}"
      Dir.chdir '/tmp'
      file = File.open(source_file, 'w')
      file.puts source_data.strip
      file.close
    end
    describe command(<<-EOF
      1>/dev/null 2>/dev/null pushd /tmp
      javac '#{source_file}'
      java -cp #{jars_cp}#{path_separator}. '#{class_name}'
      1>/dev/null 2>/dev/null popd
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /Statement returns: 42/}
      its(:stderr) { should be_empty }
    end
  end
end

