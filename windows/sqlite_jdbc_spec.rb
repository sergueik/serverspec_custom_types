# NOTE: this logic not correct under uru
if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

context 'JDBC tests' do

  # https://docs.oracle.com/javase/tutorial/jdbc/basics/retrieving.html#rs_interface
  # https://github.com/xerial/sqlite-jdbc/releases/tag/3.30.1
  # https://www.sqlite.org/download.html
  # https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.30.1/
  context 'Blob test' do
    jdbc_prefix = 'sqlite'
    tmp_path = "C:/Users/#{ENV.fetch('USERNAME')}/AppData/Local/Temp"
    jdbc_path = tmp_path
    jdbc_driver_class_name = 'org.sqlite.JDBC'
    version = '3.8.7'
    version = '3.30.1'
    jars = ["sqlite-jdbc-#{version}.jar"]
    path_separator = ';'
    jars_cp = jars.collect{|jar| "#{jdbc_path}/#{jar}"}.join(path_separator)
    database_name = "c:/Users/#{ENV.fetch('USERNAME')}/AppData/Local/Google/Chrome/User Data/Default/Login Data"
    query = 'SELECT action_url, username_value, password_value, hex(password_value) FROM logins'
    class_name = 'Test'
    source_file = "#{class_name}.java"

    source = <<-EOF

      import java.sql.Connection;
      import java.sql.DriverManager;
      import java.sql.PreparedStatement;
      import java.sql.ResultSet;
      import java.sql.SQLException;
      import java.sql.Statement;
      import java.sql.Blob;

      public class #{class_name} {

        public static void main(String[] args) throws ClassNotFoundException, SQLException {

          final String className = "#{jdbc_driver_class_name}";

          Class.forName(className);
          final String databaseName = "#{database_name}";
          String url = "jdbc:#{jdbc_prefix}:" + databaseName;

          Connection connection = null;
          try {
            connection = DriverManager.getConnection(url);
            Statement statement = connection.createStatement();
            statement.setQueryTimeout(30);
            ResultSet resultSet = statement.executeQuery("SELECT action_url, username_value, password_value FROM logins");
            while (resultSet.next()) {
              System.out.println("action_url = " + resultSet.getString("action_url") + "\n" + 
                                 "username_value = " + resultSet.getString("username_value") + "\n" +
                                  "pasword_hash = " + resultSet.getString(4)
                                 );
              // manages to load TEXT columns but fails with BLOB one
              Blob blob = resultSet.getBlob("password_value");
              int length = (int) blob.length();
              System.out.println( "password_value = " + blob.getBytes(0, length));
            }

              if (connection != null)
                connection.close();
        }
      }
    EOF
    describe command(<<-EOF
      cd "#{tmp_path}"
      write-output '#{source}' | out-file #{source_file} -encoding ASCII
      $env:PATH = "${env:PATH};c:\\java\\jdk1.8.0_101\\bin"
      javac -cp #{jars_cp} "#{source_file}"
       cmd %%- /c "java -cp #{jars_cp}#{path_separator}. #{class_name}"
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      {
        'action_url' => 'http://localhost:8080/configSubmit',
        'username_value' => '[a-z0-9:.\/]+',
        'pasword_hash' => '[a-f0-9]+',
      }.each do |k,v|
        line = "#{k} = #{v}"
        its(:stdout) { should match Regexp.new(line) }
      end
      its(:stderr) { should_not contain 'java.sql.SQLFeatureNotSupportedException' }
        # https://github.com/xerial/sqlite-jdbc/blob/master/src/main/java/org/sqlite/jdbc4/JDBC4ResultSet.java#L387
        # public Blob getBlob(int col) throws SQLException { throw unused(); }
        # protected SQLException unused() {
        #   return new SQLFeatureNotSupportedException();
        # }
        # Exception in thread "main" java.sql.SQLFeatureNotSupportedException
        # at org.sqlite.jdbc4.JDBC4ResultSet.unused(JDBC4ResultSet.java:347)
        # at org.sqlite.jdbc4.JDBC4ResultSet.getBlob(JDBC4ResultSet.java:390)
        # at Test.main(Test.java:32)
    end
  end
end
