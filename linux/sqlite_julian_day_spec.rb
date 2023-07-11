# NOTE: this logic not correct under uru
# Copyright (c) Serguei Kouzmine
if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

context 'JDBC tests' do

  context 'SQLite' do
    context 'Basic test' do
      jdbc_prefix = 'sqlite'
      jdbc_path = '/usr/share/java'
      version = '3.28.0'
      jars = ["sqlite-jdbc-#{version}.jar"]
      jdbc_driver_class_name = 'org.sqlite.JDBC'
      path_separator = ':'
      jars_cp = jars.collect{|jar| "#{jdbc_path}/#{jar}"}.join(path_separator)
      table_name = '_VARIABLES'
      class_name = 'SQLiteJulianCalendarTest'
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

              statement.executeUpdate(String.format("drop table if exists  %s;", tableName));
              statement.executeUpdate(String.format("CREATE TEMP TABLE `%s`(date_end date, time_end time, date_start date, time_start time);", tableName));
              System.out.println(String.format("Table %s was created successfully", tableName));

              PreparedStatement preparedStatement = connection.prepareStatement(
                  String.format("INSERT INTO %s (date_end, time_end, date_start, time_start) VALUES (?, ?, ?, ?)", tableName));

              preparedStatement.setDate(1, "2022-01-21");
              preparedStatement.setTime(2, "18:57:00");
              preparedStatement.setDate(3, "2022-01-21");
              preparedStatement.setTime(4, "06:57:00");
              preparedStatement.execute();

              ResultSet resultSet = statement
                  .executeQuery(String.format("select STRFTIME(\\"%%H:%%M:%%S\\", julianday(datetime(date_end,  time_end )) - julianday(datetime(date_start,  time_start ))) as time_delta from `%s`;", tableName));
              while (resultSet.next()) {
                System.out.println("time_delta = " + resultSet.getString("time_delta"));
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
          its(:stdout) { should match /time_delta = 04:57:00/}
          its(:stderr) { should_not contain /exception|failure/i }
      end
    end
  end
end


