# require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require_relative '../windows_spec_helper'

# require 'socket'

context 'JDBC tests' do
  # http://www.sqlines.com/articles/java/sql_server_jdbc_connection
  context 'MS SQL', :if => os[:family] == 'windows' do
    jdbc_prefix = 'sqlserver'
    jdbc_driver_class_name = 'com.microsoft.sqlserver.jdbc.SQLServerDriver'
    jdbc_path = "c:\\users\\sergueik\\desktop"
    database_host = 'localhost'
    database_name = 'testdb'
    path_separator = ';'
    # Exception: This driver is not configured for integrated authentication. ClientConnectionId:...
    # com.microsoft.sqlserver.jdbc.AuthenticationJNI <clinit>
    # WARNING: Failed to load the sqljdbc_auth.dll cause : no sqljdbc_auth in java.library.path
    # https://www.microsoft.com/en-us/download/details.aspx?id=11774
    jars = ['sqljdbc41.jar','sqljdbc42.jar', 'sqljdbc_6.0']
    jars_cp = jars.collect{|jar| "#{jdbc_path}\\#{jar}"}.join(';')
    table_name = 'sys.columns'
    class_name = 'TestConnectionWithWindowsAuthentication'
    sourcfile = "#{class_name}.java"
    context 'Using Windows authentication' do
      context 'Inline Java source version 1' do
        # TODO: automate
        # pushd "$env:{USERPROFILE}\Downloads"
        # copy
        # Microsoft JDBC Driver 6.0 for SQL Server\\sqljdbc_6.0\\enu\\auth\\x64\\sqljdbc_auth.dll
        # Microsoft JDBC Driver 6.0 for SQL Server\\sqljdbc_6.0\\enu\\auth\\x86\\sqljdbc_auth.dll
        # to
        # c:\Windows\system32
        source = <<-EOF
          import java.sql.Connection;
          import java.sql.DriverManager;
          import java.sql.ResultSet;
          import java.sql.Statement;

          import java.lang.reflect.*;

          public class #{class_name} {
            private static Connection connection = null;
            private static Statement statement = null;
            private static ResultSet resultSet = null;

            public static void main(String[] argv) throws Exception {
              String className = "#{jdbc_driver_class_name}";
              String tableName = "#{table_name}";
              try {
                Class driverObject = Class.forName(className);
                System.out.println("driverObject=" + driverObject);

                String serverName = "#{database_host}";
                String databaseName = "#{database_name}";
                String url = "jdbc:#{jdbc_prefix}://" + serverName + ":1434;domain=#{Socket.gethostname};databaseName="
                    + databaseName + ";integratedSecurity=true;";
                try {
                  connection = DriverManager.getConnection(url);
                  statement = connection.createStatement();
                  String query = String.format("SELECT * FROM %s", tableName);

                  resultSet = statement.executeQuery(query);

                  while (resultSet.next()) {
                    System.out.println(resultSet.getString(1) + ", "
                        + resultSet.getString(2) + ", " + resultSet.getString(3));
                  }
                } catch (Exception e1) {
                  System.out.println("Exception: " + e1.getMessage());
                } finally {
                  if (connection != null)
                    try {
                      connection.close();
                    } catch (Exception e3) {
                    }
                }
              } catch (Exception e2) {
                System.out.println("Exception: " + e2.getMessage());
              }
            }
          }
        EOF
        describe command(<<-EOF
          pushd $env:USERPROFILE
          write-output '#{source}' | out-file #{class_name}.java -encoding ASCII
          $env:PATH = "${env:PATH};c:\\java\\jdk1.8.0_101\\bin"
          javac '#{class_name}.java'
          cmd %%- /c "java  -Djava.library.path=C:\\windows\\system32 -cp #{jars_cp}#{path_separator}. #{class_name}"
        EOF
        ) do
          its(:exit_status) { should eq 0 }
          its(:stdout) { should match Regexp.new('\d+, (name|filename|status|column_guid|queuing_order|minoccur), \d+$', Regexp::IGNORECASE) }
        end
      end
      context 'Inline Java source version 2' do
        # uses Powerhell to interpolate local system environment into the java source code
        source = <<-EOF
          import java.sql.Connection;
          import java.sql.DriverManager;
          import java.sql.ResultSet;
          import java.sql.Statement;

          import java.lang.reflect.*;

          public class #{class_name} {
            private static Connection connection = null;
            private static Statement statement = null;
            private static ResultSet resultSet = null;

            public static void main(String[] argv) throws Exception {
              String className = "#{jdbc_driver_class_name}";
              String tableName = "#{table_name}";
              // not working ?
              System.setProperty("java.library.path",
                  "$($env:USERPROFILE -replace '\\\\', '\\\\')\\\\Downloads\\\\Microsoft JDBC Driver 6.0 for SQL Server\\\\sqljdbc_6.0\\\\enu\\\\auth\\\\x86\\\\");
              final Field sysPathsField = ClassLoader.class.getDeclaredField("sys_paths");
              sysPathsField.setAccessible(true);
              sysPathsField.set(null, null);
              try {
                Class driverObject = Class.forName(className);
                System.out.println("driverObject=" + driverObject);

                String serverName = "#{database_host}";
                String databaseName = "#{database_name}";
                String url = "jdbc:#{jdbc_prefix}://" + serverName + ":1434;domain=${env:COMPUTERNAME};databaseName="
                    + databaseName + ";integratedSecurity=true;";
                try {
                  connection = DriverManager.getConnection(url);
                  statement = connection.createStatement();
                  String query = String.format("SELECT * FROM %s", tableName);

                  resultSet = statement.executeQuery(query);

                  while (resultSet.next()) {
                    System.out.println(resultSet.getString(1) + ", "
                        + resultSet.getString(2) + ", " + resultSet.getString(3));
                  }
                } catch (Exception e1) {
                  System.out.println("Exception: " + e1.getMessage());
                } finally {
                  if (connection != null)
                    try {
                      connection.close();
                    } catch (Exception e3) {
                    }
                }
              } catch (Exception e2) {
                System.out.println("Exception: " + e2.getMessage());
              }
            }
          }
        EOF
        describe command(<<-EOF
          pushd $env:USERPROFILE
          $source = @"
#{source}
"@
          write-output "${source}" | out-file #{class_name}.java -encoding ASCII
          $env:PATH = "${env:PATH};c:\\java\\jdk1.8.0_101\\bin"
          javac '#{class_name}.java'
          cmd %%- /c "java  -Djava.library.path=C:\\windows\\system32 -cp #{jars_cp}#{path_separator}. #{class_name}"
        EOF
        ) do
          its(:exit_status) { should eq 0 }
          its(:stdout) { should match Regexp.new('\d+, (name|filename|status|column_guid|queuing_order|minoccur), \d+$', Regexp::IGNORECASE) }
        end
      end
    end
    table_name = 'sys.columns'
    class_name = 'TestPreparedStatement'
    sourcfile = "#{class_name}.java"
    # origin:  http://www.java2s.com/Code/JavaAPI/java.sql/PreparedStatementsetBooleanintparameterIndexbooleanx.htm
      context 'Prepared Statement' do
        # uses Powerhell to interpolate local system environment into the java source code
        source = <<-EOF
          import java.sql.Connection;
          import java.sql.DriverManager;
          import java.sql.PreparedStatement;
          import java.sql.ResultSet;
          import java.sql.Statement;

          import java.lang.reflect.*;

          public class #{class_name} {
            private static Connection connection = null;
            private static Statement statement = null;
            private static ResultSet resultSet = null;

            public static void main(String[] argv) throws Exception {
              String className = "#{jdbc_driver_class_name}";
              String tableName = "#{table_name}";
              // not working ?
              System.setProperty("java.library.path",
                  "$($env:USERPROFILE -replace '\\\\', '\\\\')\\\\Downloads\\\\Microsoft JDBC Driver 6.0 for SQL Server\\\\sqljdbc_6.0\\\\enu\\\\auth\\\\x86\\\\");
              final Field sysPathsField = ClassLoader.class.getDeclaredField("sys_paths");
              sysPathsField.setAccessible(true);
              sysPathsField.set(null, null);
              try {
                Class driverObject = Class.forName(className);
                System.out.println("driverObject=" + driverObject);

                String serverName = "#{database_host}";
                String databaseName = "#{database_name}";
                String url = "jdbc:#{jdbc_prefix}://" + serverName + ":1434;domain=${env:COMPUTERNAME};databaseName="
                    + databaseName + ";integratedSecurity=true;";
                try {
                  connection = DriverManager.getConnection(url);
                  statement = connection.createStatement();
                  statement.executeUpdate("create table survey (id int, text varchar(16) );");

                  String sql = "INSERT INTO survey (id,text) VALUES(?,?)";
                  PreparedStatement preparedStatement = connection.prepareStatement(sql);

                  preparedStatement.setInt(1, 12);
                  preparedStatement.setString(2, "test");
                  preparedStatement.executeUpdate();
    
                  resultSet = statement.executeQuery("SELECT * FROM survey");
                  while (resultSet.next()) {
                    System.out.println(resultSet.getString(2));
                  }
                  resultSet.close();
                  statement.close();
                  preparedStatement.close();
                } catch (Exception e1) {
                  System.out.println("Exception: " + e1.getMessage());
                } finally {
                  if (connection != null)
                    try {
                      connection.close();
                    } catch (Exception e3) { }
                }
              } catch (Exception e2) {
                System.out.println("Exception: " + e2.getMessage());
              }
            }
          }
        EOF
        describe command(<<-EOF
          pushd $env:USERPROFILE
          $source = @"
#{source}
"@
          write-output "${source}" | out-file #{class_name}.java -encoding ASCII
          $env:PATH = "${env:PATH};c:\\java\\jdk1.8.0_101\\bin"
          javac '#{class_name}.java'
          cmd %%- /c "java  -Djava.library.path=C:\\windows\\system32 -cp #{jars_cp}#{path_separator}. #{class_name}"
        EOF
        ) do
          its(:exit_status) { should eq 0 }
          its(:stdout) { should match Regexp.new('\d+, (name|filename|status|column_guid|queuing_order|minoccur), \d+$', Regexp::IGNORECASE) }
        end
    end

  end
  context 'MySQL', :if => os[:family] == 'windows' do
    context 'Passing connection parameters directly' do
      # origin: http://www.java2s.com/Code/Java/Database-SQL-JDBC/TestMySQLJDBCDriverInstallation.htm
      table = ''
      jdbc_prefix = 'mysql'
      jdbc_host = 'localhost'
      jdbc_driver_class_name = 'org.gjt.mm.mysql.Driver'
      # need to download com.mysql.jdbc_5.1.5 e.g. from http://www.java2s.com/Code/Jar/c/Downloadcommysqljdbc515jar.htm
      # location can be arbitrary
      jdbc_path = 'C:/java/apache-tomcat-7.0.81/webapps/basic-app-1.0-SNAPSHOT/WEB-INF/lib'
      jdbc_path = 'C:/java/apache-tomcat-8.5.45/lib'
      jars = ['com.mysql.jdbc_5.1.5.jar']
      path_separator = ';'
      jars_cp = jars.collect{|jar| "#{jdbc_path}/#{jar}"}.join(path_separator)
      database_host = 'localhost'

      database_name = 'information_schema'
      database_name = 'mysql'
      options_array = []

      {
        'useLegacyDatetimeCode' => false,
        'useJDBCCompliantTimezoneShift' => true,
        'serverTimezone' => 'UTC',
        'zeroDateTimeBehavior' => 'convertToNull',
        'useUnicode' => 'yes',
        'characterEncoding' => 'UTF-8',
      }.each { |k,v| options_array.push k + '&' + v.to_s }

      options = options_array.join('&')
      username = 'root'
      password = 'password'

      class_name = 'MySQLJDBCTest'

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
              final String url = "jdbc:#{jdbc_prefix}://" + serverName + "/" + databaseName + "?" + options;
              final String username = "#{username}";
              final String password = "#{password}";
              Connection connection = DriverManager.getConnection(url, username, password);
            } catch (Exception e) {
              System.out.println("Exception: " + e.getMessage());
              e.printStackTrace();
            }
          }
        }
      EOF
      describe command(<<-EOF
        pushd $env:USERPROFILE
        write-output '#{source}' | out-file #{class_name}.java -encoding ASCII
        $env:PATH = "${env:PATH};c:\\java\\jdk1.8.0_101\\bin"
        javac '#{class_name}.java'
        cmd %%- /c "java -cp #{jars_cp}#{path_separator}. #{class_name}"
      EOF
      ) do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should match /driverObject=class #{jdbc_driver_class_name}/ }
        its(:stderr) { should_not contain 'Exception: Communications link failure' } # mysql server is not running
        its(:stderr) { should_not contain 'Exception: Access denied for user' } # configuration mismatch
      end
    end
  end
end
