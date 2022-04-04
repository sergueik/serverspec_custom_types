# NOTE: this logic not correct under uru
if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'


context 'JDBC tests' do
  # yum install -qy mariadb-server
  # yum install -qy postgresql-jdbc.noarch
  # rpm -ql $(rpm -qa |  grep postgresql-jdbc) | grep .jar
  # NOTE: several versons of protocol exist
  # /usr/share/java/postgresql-jdbc.jar
  # /usr/share/java/postgresql-jdbc2.jar
  # /usr/share/java/postgresql-jdbc2ee.jar
  # /usr/share/java/postgresql-jdbc3.jar

  # systemctl start postgresql ; systemctl enable postgresql
  jdbc_prefix = 'postgresql'
  jdbc_path = '/usr/share/java'
  # jar tvf /usr/share/java/postgresql-jdbc3.jar |  grep Driver.class
  #  org/postgresql/Driver.class
  # https://jdbc.postgresql.org/documentation/81/load.html
  jdbc_driver_class_name = 'org.postgresql.Driver'
  jars = ['postgresql-jdbc3.jar'] # installed by yum
  path_separator = ':'
  jars_cp = jars.collect{|jar| "#{jdbc_path}/#{jar}"}.join(path_separator)
  database_host = 'localhost'
  options = ''
  database_name = 'postgres'
  username = 'postgres'
  # Will exercise attempt to connect on JDBC without password:
  # experiencing challenges setting one on Centos / MariaDB
  password =  ''

  context 'Connection check' do
    class_name = 'PostgreSQLJDBCNoPasswordTest'
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

      its(:stdout) { should contain 'driverObject=class org.postgresql.Driver'}
      its(:stdout) { should contain 'Connected to product: PostgreSQL'}
      its(:stdout) { should match /Connected to catalog: #{database_name}/}
      its(:stderr) { should_not contain 'Exception: Communications link failure' } # mysql server is not running
      its(:stderr) { should_not contain 'Exception: Access denied for user' } # configuration mismatch
      its(:stderr) { should_not contain 'Not supported' }
    end
  end
  # https://jdbc.postgresql.org/documentation/81/connect.html
  context 'Connection check (slightly different syntax)' do
    class_name = 'PostgreSQLJDBCNoPasswordiConnectionPropertiesTest'
    source_file = "#{class_name}.java"

    source = <<-EOF
      import java.sql.Connection;
      import java.sql.DriverManager;
      import java.util.Properties;

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
            final String url = "jdbc:#{jdbc_prefix}://" + serverName + "/" + databaseName;
            final String username = "#{username}";
            final String password = "#{password}";
            Properties properties = new Properties();
            properties.setProperty("user", username);
            properties.setProperty("password", password);
            // properties.setProperty("ssl","false");
            Connection connection = DriverManager.getConnection(url, properties);
            if (connection != null) {
              System.out.println("Connected to product: " + connection.getMetaData().getDatabaseProductName());
              System.out.println("Connected to catalog: " + connection.getCatalog());
              // System.out.println("Connected to: " + connection.getSchema());
              // java.sql.SQLFeatureNotSupportedException: Method org.postgresql.jdbc4.Jdbc4Connection.getSchema() is not yet implemented.
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

      its(:stdout) { should contain 'driverObject=class org.postgresql.Driver'}
      its(:stdout) { should contain 'Connected to product: PostgreSQL'}
      its(:stdout) { should match /Connected to catalog: #{database_name}/}
      its(:stderr) { should_not contain 'Exception: Communications link failure' } # mysql server is not running
      its(:stderr) { should_not contain 'Exception: Access denied for user' } # configuration mismatch
      its(:stderr) { should_not contain 'Not supported' }
      its(:stderr) { should_not contain 'The server does not support SSL' }
    end
  end
end




