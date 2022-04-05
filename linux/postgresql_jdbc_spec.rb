# NOTE: this logic not correct under uru
if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'


context 'JDBC tests' do
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
      its(:stderr) { should_not contain 'Exception: Communications link failure' } 
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
      its(:stderr) { should_not contain 'Exception: Communications link failure' } 
      its(:stderr) { should_not contain 'Exception: Access denied for user' } # configuration mismatch
      its(:stderr) { should_not contain 'Not supported' }
      its(:stderr) { should_not contain 'The server does not support SSL' }
    end
  end
# TODO: before(:all)
# CREATE TABLE accounts ( id serial PRIMARY KEY, username VARCHAR ( 50 ) UNIQUE NOT NULL, password VARCHAR ( 50 ) NOT NULL, email VARCHAR ( 255 ) UNIQUE NOT NULL, created_on TIMESTAMP NOT NULL, last_login TIMESTAMP  );
# NOTE: CURRENT_TIMESTAMP() is a function but shoulw be user without parenthesis
# INSERT INTO accounts (username, password, email, created_on) VALUES ('bob','secret','bob@mail.com',CURRENT_TIMESTAMP);
#
# SELECT count(*) <> 0 FROM accounts WHERE username = 'bob';
#
  context 'PostgreSQL specific SQL' do
    class_name = 'PostgreSQLJDBCSQLTest'
    source_file = "#{class_name}.java"
    database_name2 = 'template1'
    # NOTE when a SQL is embedded in the Java code of the test snippet need to write the source file via File class

    source_data = <<-EOF
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
            final String databaseName = "#{database_name2}";
            final String options = "#{options}";
            // Exception: Communications link failure
            final String url = "jdbc:#{jdbc_prefix}://" + serverName + "/" + databaseName;
            final String username = "#{username}";
            final String password = "#{password}";
            Properties properties = new Properties();
            properties.setProperty("user", username);
            properties.setProperty("password", password);
            Connection connection = DriverManager.getConnection(url, properties);
            if (connection != null) {
              System.out.println("Connected to product: " + connection.getMetaData().getDatabaseProductName());
              System.out.println("Connected to catalog: " + connection.getCatalog());

              String query = "SELECT count(*) <> 0 FROM accounts WHERE username = 'bob';";
              System.out.println("Executing count query: " + query);
              ResultSet resultSet = connection.createStatement().executeQuery(query);
              resultSet.next();
              // NOTE: failing with Postgres: resultSet().first()
              // org.postgresql.util.PSQLException: Operation requires a scrollable ResultSet, but this ResultSet is FORWARD_ONLY
              final boolean cnt = resultSet.getBoolean(1);
              System.out.println("count: " + cnt);
              resultSet.close();
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

      its(:stdout) { should contain 'driverObject=class org.postgresql.Driver'}
      its(:stdout) { should contain 'Connected to product: PostgreSQL'}
      its(:stdout) { should match /Connected to catalog: #{database_name2}/}
      its(:stdout) { should match /count: true/}
      its(:stderr) { should_not contain 'Exception: Communications link failure' } 
      its(:stderr) { should_not contain 'Exception: Access denied for user' } # configuration mismatch
      its(:stderr) { should_not contain 'Not supported' }
      its(:stderr) { should_not contain 'The server does not support SSL' }
    end
  end
  context 'Prepared Statement' do
    class_name = 'PostgreSQLJDBCPreparedStatementTest'
    source_file = "#{class_name}.java"

    source = <<-EOF
      import java.sql.Connection;
      import java.sql.DriverManager;
          import java.sql.PreparedStatement;
          import java.sql.Connection;
          import java.sql.DriverManager;
          import java.sql.PreparedStatement;
          import java.sql.ResultSet;
          import java.sql.Statement;
      public class #{class_name} {
            private static String className = "#{jdbc_driver_class_name}";
            private static Connection connection = null;
            private static Statement statement = null;
            private static ResultSet resultSet = null;
        public static void main(String[] argv) throws Exception {
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
            connection = DriverManager.getConnection(url, username, "");
            if (connection != null) {
                try {
                
                  statement = connection.createStatement();
                  statement.executeUpdate("create table if not exists survey (id int, text varchar(16) );");

                  String sql = "INSERT INTO survey (id,text) VALUES(?,?)";
                  PreparedStatement preparedStatement = connection.prepareStatement(sql);

                  preparedStatement.setInt(1, 12);
                  preparedStatement.setString(2, "test");
                  preparedStatement.executeUpdate();
    
                  resultSet = statement.executeQuery("SELECT * FROM survey");
                  while (resultSet.next()) {
                    System.out.println("text: " + resultSet.getString(2));
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
      its(:stdout) { should contain 'text: test'}
    end
  end
end




