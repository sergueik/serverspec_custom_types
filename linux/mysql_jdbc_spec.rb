# NOTE: this logic not correct under uru
if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'


context 'JDBC tests' do

  context 'MySQL' do
    # yum install -qy mysql-connector-java.noarch mariadb-server
    # systemctl start mariadb ; systemctl enable mariadb
    # https://linuxize.com/post/install-mariadb-on-centos-7/
    # https://support.rackspace.com/how-to/mysql-resetting-a-lost-mysql-root-password/
    jdbc_prefix = 'mysql'
    jdbc_driver_class_name = 'com.microsoft.sqlserver.jdbc.SQLServerDriver'
    jdbc_path = '/usr/share/java'
    # jar tvf /usr/share/java/mysql-connector-java.jar |  grep Driver.class
    #  com/mysql/jdbc/Driver.class
    #  org/gjt/mm/mysql/Driver.class
    jdbc_driver_class_name = 'org.gjt.mm.mysql.Driver'
    jars = ['mysql-connector-java.jar'] # installed by yum
    path_separator = ':'
    jars_cp = jars.collect{|jar| "#{jdbc_path}/#{jar}"}.join(path_separator)
    database_host = 'localhost'
    options = 'useUnicode=true'
    database_host = 'localhost'
    database_name = 'information_schema'
    # unable to set password access in information_schema:
    # ERROR 1109 (42S02): Unknown table 'user' in information_schema
    database_name = 'mysql'
    username = 'root'
    # Will exercise attempt to connect on JDBC without password:
    # experiencing challenges setting one on Centos / MariaDB
    password =  ''
    class_name = 'MySQLJDBCNoPasswordTest'
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
        its(:stdout) { should match /Connected to catalog: #{database_name}/}
        its(:stderr) { should_not contain 'Exception: Communications link failure' } # mysql server is not running
        its(:stderr) { should_not contain 'Exception: Access denied for user' } # configuration mismatch
        its(:stderr) { should_not contain 'Not supported' }
    end
  end
end
