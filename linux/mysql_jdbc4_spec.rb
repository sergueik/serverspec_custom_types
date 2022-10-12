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
  # jar tvf /usr/share/java/mysql-connector-java.jar | grep Driver.class
  # com/mysql/jdbc/Driver.class
  # com/mysql/cj/jdbc/Driver.class

  # jdbc_driver_class_name = 'com.microsoft.sqlserver.jdbc.SQLServerDriver'
  jdbc_driver_class_name = 'com.mysql.jdbc.Driver'
  jars = ['mysql-connector-java.jar'] # installed by yum
  # on a vanilla Ubuntu system
  # cd ~sergueik/src/selenium_java/datatxt-cachedb
  # mvn package
  # sudo cp target/lib/mysql-connector-java-8.0.28.jar /usr/share/java/
  # cd /usr/share/java/
  # sudo ln -fs mysql-connector-java-8.0.28.jar mysql-connector-java.jar
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
  
  
  password = 'password'
  context 'Count Queries' do
    class_name = 'MySQLJDBCCountQueryTest'
    database_name = 'test'
    options = 'useUnicode=true&characterEncoding=UTF-8'
    source_file = "#{class_name}.java"

    source_data = <<-EOF
      import java.sql.Connection;
      import java.sql.DriverManager;
      import java.sql.ResultSet;
      import java.sql.Statement;
      import java.sql.SQLException;
      import java.sql.PreparedStatement;
      import java.sql.CallableStatement;
      import java.util.List;
      import java.util.Map;
      import java.util.ArrayList;
      import java.util.Arrays;
      import java.util.List;

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
            // when password is blank JDBC will attempt to connect without using password.
            // as opposed to calling the DriverManager.getConnection with just url which fails.
            Connection connection = DriverManager.getConnection(url, username, "");

            if (connection != null) {
              System.out.println("Connected to product: " + connection.getMetaData().getDatabaseProductName());
              System.out.println("Connected to catalog: " + connection.getCatalog());
              List<Integer> ids = new ArrayList<Integer>();
              ids.add(1);
              ids.add(2);
              ids.add(3);
              queryByIds(ids,connection);
              connection.close();
            } else {
              System.out.println("Failed to connect");
            }
          } catch (Exception e) {
            System.out.println("Exception: " + e.getMessage());
            e.printStackTrace();
          }
        }
	public static List<Long> queryByIds(List<Integer> ids, Connection connection) {

		int size = ids.size();
		String marks[] = new String[size];
		for (int cnt = 0; cnt != size; cnt++) {
			marks[cnt] = "?";
		}
		String SQL = "select id from hosts " + String.format("where id in (%s)",
				String.join(",", Arrays.asList(marks)));

		System.out.println("query : " + SQL);
		List<Long> results = new ArrayList<>();
		PreparedStatement pstmt = null;

		ResultSet rs = null;
		try {
			pstmt = connection.prepareStatement(SQL);
			int cnt = 1;
			for (int id : ids) {
				pstmt.setInt(cnt, id);
        System.out.println("add query arg "  + cnt + ": " + id);
				cnt++;
			}

			rs = pstmt.executeQuery();
			while (rs.next()) {
				final Long result = rs.getLong(1);
				results.add(result);
				System.out.println("result: " + result);
			}

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			try {
				rs.close();
				pstmt.close();
				connection.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		return results;
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
      1>/dev/null 2>/dev/null cd /tmp
      javac '#{source_file}'
      java -cp #{jars_cp}#{path_separator}. '#{class_name}'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      #  undefined group option: /query : select id from hosts where id in (?,?,?)/m
      its(:stdout) { should contain 'query : select id from hosts where id in \(\?,\?,\?\)'}
      its(:stdout) { should match /result: 2/}
      its(:stderr) { should be_empty }
    end
  end
end







