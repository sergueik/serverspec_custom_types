# NOTE: this logic not correct under uru
if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'


context 'JDBC tests' do
  catalina_home = '/opt/tomcat'
  path_separator = ':'
  application = 'Tomcat Application Name'
  jdbc_path = "#{catalina_home}/webapps/#{application}/WEB-INF/lib/"
  config_file_path = "#{catalina_home}/conf/context.xml"

  # yum erase -q -y java-1.8.0-openjdk
  # yum install -q -y java-1.8.0-openjdk-devel
  context 'Postgresql' do
    # for quick setup of a dummy Postgresql database, see
    # https://www.linode.com/docs/databases/postgresql/how-to-install-postgresql-relational-databases-on-centos-7/
    # yum install -q -y postgresql-server postgresql-contrib
    # postgresql-setup initdb
    # systemctl start postgresql
    # systemctl enable postgresql
    # passwd #{username}
    # su - #{username}
    # psql -d template1 -c "ALTER USER postgres WITH PASSWORD '...';"
    # psql postgres
    # postgres=#
    #     \list
    #                                      List of databases
    #       Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
    #    -----------+----------+----------+-------------+-------------+-----------------------
    #     postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
    #     template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres
    #               |          |          |             |             | postgres=CTc/postgres
    #     template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres
    #               |          |          |             |             | postgres=CTc/postgres
    #     \q
    # https://jdbc.postgresql.org/download.html
    # hack: New password:
    # BAD PASSWORD: The password is the same as the old one
    # By default PostgreSQL uses IDENT-based authentication and this will never allow you to login via -U and -W options. Allow username and password based authentication from your application by appling 'trust' as the authentication method for the JIRA database user. You can do this by modifying the pg_hba.conf file.

    # # IPv4 local connections:
    # host    all             all             127.0.0.1/32            ident
    # + host    all             all             127.0.0.1/32            trust
    # IPv6 local connections:
    # host    all             all             ::1/128                 ident
    # + host    all             all             ::1/128                 trust
    $POSTRGES_PASSWORD = ENV.fetch('POSTRGES_PASSWORD', 'postgres') # BAD PASSWORD: The password is the name of the user
    jdbc_version = '42.2.6'
    postgres_version = '9.2.24'

    jdbc_driver_class_name = 'org.postgresql.Driver'
    username = 'postgres'
    database = 'template1'
    password = $POSTRGES_PASSWORD
    tmp_path = '/tmp'
    jdbc_path = '/tmp'
    jdbc_jar = "postgresql-#{jdbc_version}.jar"
    jars = [jdbc_jar]
    jars_cp = jars.collect{|jar| "#{jdbc_path}/#{jar}"}.join(path_separator)
    context 'Basic' do
      describe file('/var/lib/pgsql/data/pg_hba.conf') do
        its(:content) { should match Regexp.new '^\s*host\s+all\s+all\s+127.0.0.1/32\s+trust' }
        its(:content) { should_not match Regexp.new '^\s*host\s+all\s+all\s+127.0.0.1/32\s+ident' }
      end
      # pushd #{tmp_path}
      # jar xvf '#{jdbc_path}/#{jdbc_jar}' META-INF/maven/org.postgresql/postgresql/pom.properties
      # inflated: META-INF/maven/org.postgresql/postgresql/pom.properties
      # grep -q 'version=#{jar_version}' 'META-INF/maven/org.postgresql/postgresql/pom.properties'
      # jar xvf '#{jdbc_path}/#{jdbc_jar}' META-INF/MANIFEST.MF
      # grep -q 'Bundle-Version: #{jar_version}'
      # http://zetcode.com/java/postgresql/

      # http://www.java2s.com/Tutorials/Java/JDBC/0015__JDBC_PostgreSQL.htm
      # see also:
      # https://www.mkyong.com/jdbc/jdbc-callablestatement-postgresql-stored-function/
      class_name = 'TestPgTryJdbc'
      source_file = "#{class_name}.java"
      source = <<-EOF
        import java.sql.Connection;
        import java.sql.DriverManager;

        public class #{class_name} {
          static private final String applicationName = "Driver Tests";
          static private final String logLevel = "DEBUG";
          static private final int protocolVersion =  0;
          static private String connectionURL = null;
          static private String host = "127.0.0.1";
          static private String port = "5432";
          static private String database = "#{database}";

          public static void main(String[] argv) throws Exception {
            Class.forName("#{jdbc_driver_class_name}");

            // based on: https://github.com/pgjdbc/pgjdbc/blob/master/pgjdbc/src/test/java/org/postgresql/test/jdbc2/ConnectionTest.java
            connectionURL = "jdbc:postgresql://"
                + host + ":" + port + "/" + database
                + "?ApplicationName=" + applicationName
                + ((logLevel != null && !logLevel.equals("")) ?
                ("&loggerLevel=" + logLevel ) : "");

            Connection connection = DriverManager.getConnection(
                connectionURL, "#{username}",
                "#{password}");

            if (connection != null) {
              System.out.println("Connected");
            } else {
              System.out.println("Failed to connect");
            }
          }
        }

      EOF
      # https://www.postgresql.org/docs/7.2/jdbc.html
      describe command(<<-EOF
        1>/dev/null 2>/dev/null pushd '#{tmp_path}'
        echo '#{source}' > '#{source_file}'
        javac '#{source_file}'
        export CLASSPATH=#{jars_cp}#{path_separator}.
        # NOTE: user context switch is playing no effect
        su #{username} -c "java '#{class_name}'"
        1>/dev/null 2>/dev/null popd
      EOF

      ) do
        its(:exit_status) { should eq 0 }
        # Exception in thread "main" org.postgresql.util.PSQLException: FATAL: Ident authentication failed for user "postgres"
        its(:stderr) { should contain Regexp.new(Regexp.escape('FINE: Connecting with URL: jdbc:postgresql://127.0.0.1:5432/template1?ApplicationName=Driver Tests&loggerLevel=DEBUG')) }
        its(:stderr) { should contain "FINE: PostgreSQL JDBC Driver #{jdbc_version}" }
        its(:stdout) { should contain 'Connected' }
      end
    end
    context 'Read SQL query from the file' do
      describe file('/var/lib/pgsql/data/pg_hba.conf') do
        its(:content) { should match Regexp.new '^\s*host\s+all\s+all\s+127.0.0.1/32\s+trust' }
        its(:content) { should_not match Regexp.new '^\s*host\s+all\s+all\s+127.0.0.1/32\s+ident' }
      end
      # http://www.java2s.com/Tutorials/Java/JDBC/0015__JDBC_PostgreSQL.htm
      # see also:
      # http://zetcode.com/java/postgresql/

      tmp_path = '/tmp'
      sample_query_file = "#{tmp_path}/query.txt"
      # NOTE: no need in \g at the end of SQL statement when JDBC-delivered
      sample_query_data = <<-EOF
        SELECT VERSION()
      EOF
      class_name = 'TestQueryPostgress'
      source_file = "#{tmp_path}/#{class_name}.java"
      source_data = <<-EOF
        import java.sql.Connection;
        import java.sql.DriverManager;
        import java.io.File;
        import java.io.FileReader;
        import java.io.IOException;
        import java.sql.Connection;
        import java.sql.DriverManager;
        import java.sql.ResultSet;
        import java.sql.Statement;
        import java.sql.SQLException

        public class #{class_name} {
          static private final String applicationName = "Driver Tests";
          static private final String logLevel = "DEBUG";
          static private final int protocolVersion =  0;
          static private String connectionURL = null;
          static private String host = "127.0.0.1";
          static private String port = "5432";
          static private String database = "#{database}";

          public static void main(String[] argv) throws Exception {
            Class.forName("#{jdbc_driver_class_name}");

            // based on: https://github.com/pgjdbc/pgjdbc/blob/master/pgjdbc/src/test/java/org/postgresql/test/jdbc2/ConnectionTest.java
            connectionURL = "jdbc:postgresql://" + host + ":" + port + "/" + database + "?ApplicationName=" + applicationName + ((logLevel != null && !logLevel.equals("")) ? ("&loggerLevel=" + logLevel ) : "");
            Connection connection = DriverManager.getConnection( connectionURL, "#{username}", "#{password}");
            if (connection != null) {
              System.out.println("Connected");
            } else {
              System.out.println("Failed to connect");
            }
            Statement statement = connection.createStatement();
            String fileName = "#{sample_query_file}";
            String query = deserializeString(new File(fileName));

            try {
              ResultSet m_ResultSet = statement.executeQuery(query);
              while (m_ResultSet.next()) {
                System.out.println(m_ResultSet.getString(1));
              }
            } catch (SQLException e) {
              // Logger logger = Logger.getLogger(#{class_name}.class.getName());
              // logger.log(Level.SEVERE, e.getMessage(), e);
              System.err.println(e.getMessage());
            }
          }
          // origin: http://www.java2s.com/Tutorial/Java/0180__File/LoadatextfilecontentsasaString.htm
          public static String deserializeString(File file)
          throws IOException {
              int len;
              char[] chr = new char[4096];
              final StringBuffer buffer = new StringBuffer();
              final FileReader reader = new FileReader(file);
              try {
                  while ((len = reader.read(chr)) > 0) {
                      buffer.append(chr, 0, len);
                  }
              } finally {
                  reader.close();
              }
              return buffer.toString();
          }
        }

      EOF
      before(:each) do
        $stderr.puts "Writing #{sample_query_file}"
        file = File.open(sample_query_file, 'w')
        file.puts sample_query_data
        file.close

        $stderr.puts "Writing #{source_file}"
        file = File.open(source_file, 'w')
        file.puts source_data
        file.close
        Specinfra::Runner::run_command( <<-EOF
          systemctl status -l postgresql
      EOF
      )
      end
      describe command(<<-EOF
        1>/dev/null 2>/dev/null pushd '#{tmp_path}'
        javac '#{source_file}'
        export CLASSPATH=#{jars_cp}#{path_separator}.
        # NOTE: user context switch is playing no effect
        su #{username} -c "java '#{class_name}'"
        1>/dev/null 2>/dev/null popd
      EOF

      ) do
        its(:exit_status) { should eq 0 }
        # Exception in thread "main" org.postgresql.util.PSQLException: FATAL: Ident authentication failed for user "postgres"
        its(:stderr) { should contain Regexp.new(Regexp.escape('FINE: Connecting with URL: jdbc:postgresql://127.0.0.1:5432/template1?ApplicationName=Driver Tests&loggerLevel=DEBUG')) }
        its(:stderr) { should contain "FINE: PostgreSQL JDBC Driver #{jdbc_version}" }
        its(:stdout) { should contain "PostgreSQL #{postgres_version} on" }
      end
    end
    context 'Alternative New gen PostgreSQL JDBC driver with extra and advanced features supported by postgreSQL' do
      # http://impossibl.github.io/pgjdbc-ng/
      # https://github.com/impossibl/pgjdbc-ng
      jdbc_version = '0.8.2'
      jdbc_driver_class_name = 'com.impossibl.postgres.jdbc.PGDataSource'
      xda_data_source_class_name = 'com.impossibl.postgres.jdbc.xa.PGXADataSource'
      jdbc_connection_pool_data_source_class_name = 'com.impossibl.postgres.jdbc.PGConnectionPoolDataSource'
      username = 'postgres'
      database = 'template1'
      password = $POSTRGES_PASSWORD
      tmp_path = '/tmp'
      jar_path = '/tmp'
      jdbc_jar = "pgjdbc-ng-#{jdbc_version}.jar"
      jars = [jdbc_jar]
      jars_cp = jars.collect{|jar| "#{jar_path}/#{jar}"}.join(path_separator)

      # https://github.com/impossibl/pgjdbc-ng/blob/develop/driver/src/test/java/com/impossibl/postgres/jdbc/ConnectionTest.java
      # https://github.com/impossibl/pgjdbc-ng/blob/develop/driver/src/test/java/com/impossibl/postgres/jdbc/TestUtil.java
      class_name = 'TestPgNgJDBC'
      source_file = "#{class_name}.java"
      source = <<-EOF
        import static com.impossibl.postgres.jdbc.JDBCSettings.CI_APPLICATION_NAME;
        import static com.impossibl.postgres.jdbc.JDBCSettings.CI_CLIENT_USER;

        import java.sql.Connection;
        import java.sql.PreparedStatement;
        import java.sql.ResultSet;
        import java.sql.SQLException;
        import java.sql.SQLTimeoutException;
        import java.sql.SQLWarning;
        import java.sql.Statement;

        import java.util.HashMap;
        import java.util.Map;
        import java.util.Properties;
        import java.util.Random;
        import java.util.concurrent.Executor;


        public class #{class_name} {
          static private final String applicationName = "Driver Tests";
          static private final String logLevel = "DEBUG";
          static private final int protocolVersion =  0;
          static private String connectionURL = null;
          static private String host = "127.0.0.1";
          static private String port = "5432";
          static private String database = "#{database}";

          public static void main(String[] argv) throws Exception {
            Class.forName("#{jdbc_driver_class_name}");

            connectionURL = "jdbc:pgsql://"
                + host + ":" + port + "/" + database;
                // NOTE: can append the query

            Properties properties = new Propeties();
            properties.setProperty("user", "#{username}");
            properties.setProperty("password", "#{password}");

            Connection connection = DriverManager.getConnection(
                connectionURL, properties);

            if (connection != null) {
              System.out.println("Connected");
              connection.close();
            } else {
              System.out.println("Failed to connect");
            }

          }
        }

      EOF
      # https://www.postgresql.org/docs/7.2/jdbc.html
      describe command(<<-EOF
        1>/dev/null 2>/dev/null pushd '#{tmp_path}'
        echo '#{source}' > '#{source_file}'
        javac '#{source_file}'
        export CLASSPATH=#{jars_cp}#{path_separator}.
        # NOTE: user context switch is playing no effect
        su #{username} -c "java '#{class_name}'"
        1>/dev/null 2>/dev/null popd
      EOF

      ) do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should contain 'Connected' }
      end
    end
  end

  context 'Oracle' do
    context 'Using tomcat context.xml' do
      # <Resource
      #    name="jdbc/<entity>"
      #    auth="Container"
      #    type="javax.sql.DataSource"
      #    driverClassName="oracle.jdbc.OracleDriver"
      #    url="jdbc:oracle:thin:<username>/<password>@hostname:port/sid"
      #    factory="org.apache.tomcat.dbcp.dbcp.BasicDataSourceFactory"
      # />

      jdbc_driver_class_name = 'oracle.jdbc.driver.OracleDriver'
      database_query = 'SELECT DUMMY FROM dual'
      jars = ['ojdbc7.jar']
      jars_cp = jars.collect{|jar| "#{jdbc_path}/#{jar}"}.join(path_separator)
      entity = 'confluence'
      class_name = 'TestConnectionWithCredentialsInUrl'
      source_file = "#{class_name}.java"
      source = <<-EOF

        import java.io.File;
        import java.io.FileInputStream;
        import java.io.IOException;

        import javax.xml.parsers.DocumentBuilder;
        import javax.xml.parsers.DocumentBuilderFactory;
        import javax.xml.parsers.ParserConfigurationException;
        import javax.xml.xpath.XPath;
        import javax.xml.xpath.XPathConstants;
        import javax.xml.xpath.XPathExpressionException;
        import javax.xml.xpath.XPathFactory;

        import org.w3c.dom.Document;
        import org.w3c.dom.Element;
        import org.xml.sax.SAXException;

        import java.sql.Connection;
        import java.sql.DriverManager;
        import java.sql.ResultSet;
        import java.sql.Statement;
        import java.sql.SQLException;

        public class #{class_name} {

          public static void main(String[] args) throws SAXException, IOException, ParserConfigurationException, XPathExpressionException, ClassNotFoundException, SQLException {
            DocumentBuilder db = (DocumentBuilderFactory.newInstance())
                .newDocumentBuilder();
            String configFilePath = "#{config_file_path}";
            Document document = db.parse(new FileInputStream(new File(configFilePath)));
            XPath xpath = (XPathFactory.newInstance()).newXPath();
            String entity = "#{entity}";
            String xpathLocator = String
                .format("/Context/Resource[ @name = \\"jdbc/%s\\"]", entity);
            System.err.println(String.format("Looking for \\"%s\\"", xpathLocator));
            Element userElement = (Element) xpath.evaluate(xpathLocator, document,
                XPathConstants.NODE);
            String username = userElement.getAttribute("username");
            String password = userElement.getAttribute("password");
            Class.forName("#{jdbc_driver_class_name}");

            String url = userElement.getAttribute("url");
            Connection connection = null;
            if (username == null || username.isEmpty()) {
              System.err.println(String.format("Connecting to %s", url));
              connection = DriverManager.getConnection(url);
            } else {
              System.err.println(String.format("Connecting to %s as \\"%s\\"/\\"%s\\"", url,
                  username, password));
              connection = DriverManager.getConnection(url, username, password);
            }

            Statement statement = connection.createStatement();
            String query = "#{database_query}";

            ResultSet m_ResultSet = statement.executeQuery(query);

            while (m_ResultSet.next()) {
              System.out.println(m_ResultSet.getString(1));
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
        its(:stdout) { should contain 'X' }
      end
    end
    context 'Passing connection parameters directly' do
      # based on:
      # http://www.java2s.com/Tutorial/Java/0340__Database/ConnectwithOraclesJDBCThinDriver.htm
      # https://confluence.atlassian.com/doc/configuring-an-oracle-datasource-in-apache-tomcat-339739363.html
      jdbc_prefix = 'oracle:thin'
      port_number = 3203
      jdbc_driver_class_name = 'oracle.jdbc.driver.OracleDriver'
      jars = ['ojdbc7.jar']
      jars_cp = jars.collect{|jar| "#{jdbc_path}/#{jar}"}.join(path_separator)
      database_host = 'localhost'
      database_query = 'SELECT DUMMY FROM dual'
      sid_name = 'sid'
      username = 'sa'
      password = 'password'
      class_name = 'TestWithUserPassword'
      source_file = "#{class_name}.java"
      source = <<-EOF

        import java.sql.Connection;
        import java.sql.DriverManager;
        import java.sql.ResultSet;
        import java.sql.Statement;

        public class #{class_name} {

          public static void main(String[] args) throws Exception {
            Connection connection = getConnection();
            Statement statement = connection.createStatement();
            String query = "#{database_query}";
            ResultSet resultSet = statement.executeQuery(query);
            while (resultSet.next()) {
              System.out.println(resultSet.getString(1));
            }
            resultSet.close();
            statement.close();
            connection.close();
          }

          private static Connection getConnection() throws Exception {
            String driver = "#{jdbc_driver_class_name}";
            try {
              Class.forName(driver);
            } catch (Exception e) {
              System.out.println("Exception: " + e.getMessage());
            }
            String databaseHost = "#{database_host}";
            int portNumber = #{port_number};
            String sidName = "#{sid_name}";
            String url = "jdbc:#{jdbc_prefix}:@//" + databaseHost + ":" + portNumber + "/"
                + sidName;
            String username = "#{username}";
            String password = "#{password}";
            return DriverManager.getConnection(url, username, password);
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
        its(:stdout) { should contain 'X' }
        its(:stderr) { should be_empty }
      end
    end
  end
  context 'MS SQL' do

    jdbc_prefix = 'microsoft:sqlserver'
    jars = ['sqljdbc41.jar','sqljdbc42.jar', 'sqljdbc_6.0']
    jars_cp = jars.collect{|jar| "#{jdbc_path}/#{jar}"}.join(':')

    context 'Using tomcat context.xml' do
      # based on:
      # https://stackoverflow.com/questions/25259836/how-to-get-attribute-value-using-xpath-in-java
      # http://www.java2s.com/Code/Java/Development-Class/CommandLineParser.htm
      # http://www.java2s.com/Code/Java/Database-SQL-JDBC/Connecttoadatabaseandreadfromtable.htm

      # <Resource name="jdbc/database_name"
      #    auth="Container"
      #    factory="org.apache.tomcat.dbcp.dbcp.BasicDataSourceFactory"
      #    driverClassName="com.microsoft.sqlserver.jdbc.SQLServerDriver"
      #    type="javax.sql.DataSource"
      #    username = "<username>"
      #    password = "<password>"
      #    url="jdbc:sqlserver://database_host;databaseName=database_name;"
      #    removeAbandoned="true"
      #    removeAbandonedTimeout="30"
      #    logAbandoned="true" />
      #
      # <Resource
      #    name = "jdbc/<entity>"
      #    auth = 'Container'
      #    type = 'javax.sql.DataSource'
      #    driverClassName = 'oracle.jdbc.OracleDriver'
      #    url = "jdbc:oracle:thin:@//<hostname>:<port>/<sid>"
      #    username = "<username>"
      #    password = "<password>"
      #    connectionProperties = 'SetBigStringTryClob = true'
      #    accessToUnderlyingConnectionAllowed = 'true'
      #    maxTotal = '60'
      #    maxIdle = '20'
      #    maxWaitMillis = '10000'
      # />

      table_name = 'dbo.items'
      entity = 'Entity Name'
      class_name = 'TestConnectionWithXMLXpathReader'
      source_file = "#{class_name}.java"
      source = <<-EOF
        import java.io.File;
        import java.io.FileInputStream;
        import java.io.IOException;

        import javax.xml.parsers.DocumentBuilder;
        import javax.xml.parsers.DocumentBuilderFactory;
        import javax.xml.parsers.ParserConfigurationException;
        import javax.xml.xpath.XPath;
        import javax.xml.xpath.XPathConstants;
        import javax.xml.xpath.XPathExpressionException;
        import javax.xml.xpath.XPathFactory;

        import org.w3c.dom.Document;
        import org.w3c.dom.Element;
        import org.xml.sax.SAXException;

        import java.sql.Connection;
        import java.sql.DriverManager;
        import java.sql.ResultSet;
        import java.sql.Statement;
        import java.sql.SQLException;

        public class Test #{class_name} {

          public static void main(String[] args) throws SAXException, IOException, ParserConfigurationException, XPathExpressionException, ClassNotFoundException, SQLException {
            String tableName = "#{table_name}";
            DocumentBuilder db = (DocumentBuilderFactory.newInstance())
                .newDocumentBuilder();
            String configFilePath = "#{config_file_path}";
            Document document = db.parse(new FileInputStream(new File(configFilePath)));
            XPath xpath = (XPathFactory.newInstance()).newXPath();
            String entity = "#{entity}";
            // NOTE: quotes
            String xpathLocator = String
                .format("/Context/Resource[ @name = \\"jdbc/%s\\"]", entity);
            System.err.println(String.format("Looking for \\"%s\\"", xpathLocator));
            Element userElement = (Element) xpath.evaluate(xpathLocator, document,
                XPathConstants.NODE);
            String username = userElement.getAttribute("username");
            String password = userElement.getAttribute("password");
            String driverClassName = userElement.getAttribute("driverClassName");
            Class.forName(driverClassName);

            String url = userElement.getAttribute("url");
            System.err.println(
                String.format("connecting to %s as \\"%s\\"/\\"%s\\"", url, username, password));
            Connection m_Connection = DriverManager.getConnection(url, username,
                password);

            Statement m_Statement = m_Connection.createStatement();
            String query = String.format("SELECT * FROM %s", tableName);

            ResultSet m_ResultSet = m_Statement.executeQuery(query);

            while (m_ResultSet.next()) {
              System.out.println(m_ResultSet.getString(1) + ", "
                  + m_ResultSet.getString(2) + ", " + m_ResultSet.getString(3));
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
      its(:stdout) { should match Regexp.new('\d+, \d+, \d+$', Regexp::IGNORECASE) }
    end
  end
  context 'Passing connection parameters directly' do
    # origin: http://docs.oracle.com/javase/tutorial/jdbc/basics/processingsqlstatements.html

    database_table = 'name of the table'
    jdbc_prefix = 'sqlserver'
    jdbc_driver_class_name = 'com.microsoft.sqlserver.jdbc.SQLServerDriver'
    database_host = 'localhost'
    database_name = ''
    username = 'sa'
    password =  'password'
    class_name = 'TestConnectionSimple'
    source_file = "#{class_name}.java"

    source = <<-EOF
      import java.sql.CallableStatement;
      import java.sql.Connection;
      import java.sql.DriverManager;
      import java.sql.ResultSet;
      import java.sql.Statement;

      public class #{class_name} {
        public static void main(String[] argv) throws Exception {
          Class.forName("#{jdbc_driver_class_name}");

          Connection connection = DriverManager.getConnection(
              "jdbc:#{jdbc_prefix}://#{database_host};databaseName=#{database_name}",
              "#{username}", "#{password}");

          Statement statement = null;
          String query = "select * from #{database_table}";
          try {
            statement = connection.createStatement();
            ResultSet resultSet = statement.executeQuery(query);
            while (resultSet.next()) {
              String id = resultSet.getString("ITEM_REFERENCE_ID");
              System.out.println("ITEM_REFERENCE_ID: " + id);
            }
          } catch (Exception e) {
            e.printStackTrace();
          } finally {
            if (statement != null) {
              statement.close();
            }
          }
        }
      }
    EOF
    describe command(<<-EOF
      pushd $env:TEMP
      1>/dev/null 2>/dev/null pushd /tmp
      echo '#{source}' > '#{source_file}'
      javac '#{source_file}'
      java -cp #{jars_cp}#{path_separator}. '#{class_name}'
      1>/dev/null 2>/dev/null popd
    EOF
    ) do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should match /ITEM_REFERENCE_ID: \d+/}
      end
    end
  end
  # When JSBC SQL DriverSpy class is engaged to log the database operation,
  # the JDBC Connection string would switch the URL prefix to the "jdbc:log4jdbc" instead of "jdbc:"
  # and would read like "jdbc:log4jdbc:mysql://<URL>:<PORT>/<CONNECTION ARGUMENTS>"
  # the driverClassName would become "net.sf.log4jdbc.DriverSpy"
  # the "org.slf4j.slf4j-api" will be responsible for loading the driver jar from classpath
  # it will be specified, usually through the appliction properties, what is to be logged
  # and the bare bones code in this example would stop work
  # further info:
  # https://stackoverflow.com/questions/17988231/how-to-log-jdbc-connection-activity
  # http://kveeresham.blogspot.com/2015/03/logging-jdbc-activities-using-log4jdbc.html
  # http://www.java2s.com/Tutorials/Java/log4j/0080__log4j_Log_to_Database.htm
  # note this is a diferent matter than JDBC log appender.
  # https://coderanch.com/t/529904/databases/log-jdbcplus-JDBCAppender-log-xml
end
