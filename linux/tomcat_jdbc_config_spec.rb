require 'spec_helper'

context 'Tomcat server.xml test' do
  catalina_home = '/usr/share/tomcat'
  catalina_home =  '/tmp'
  driver_class_name = 'oracle.jdbc.OracleDriver'
  resource_name_fragment = 'jdbc'
  context 'JDBC resource attributes' do
    # <Resource
    #     name = "jdbc/entity"
    #     auth = 'Container'
    #     type = 'javax.sql.DataSource'
    #     driverClassName = 'oracle.jdbc.OracleDriver'
    #     url = "jdbc:oracle:thin:@//hostname:port/sid"
    #     username = "username"
    #     password = "password"
    #     connectionProperties = 'SetBigStringTryClob = true'
    #     accessToUnderlyingConnectionAllowed = 'true'
    #     maxTotal = '60'
    #     maxIdle = '20'
    #     maxWaitMillis = '10000'
    # />
    #
    # only collects attributes of jdbc resource
    describe command(<<-EOF
      xmllint -xpath '//Resource[contains(@name,"#{resource_name_fragment}")]/@*' '#{catalina_home}/conf/server.xml' | tr ' ' '\\n'
    EOF
    ) do
      [
        'type="javax.sql.DataSource"',
        'auth="Container"',
        'name="Database"',
        "driverClassName=\"#{driver_class_name}\"",
      ].each do |line|
        its(:stdout) { is_expected.to match Regexp.escape(line) }
        its(:stderr) { is_expected.to be_empty }
        # the expect syntax does not support operator matchers, so you must pass a matcher to `#to`.
        # its(:stderr) { is_expected.to not( contain 'failed to load external entity' )}
        # undefined local variable or method `is_not_expected'
        # its(:stderr) { is_not_expected.to contain 'failed to load external entity' }
        its(:stderr) { should_not contain 'failed to load external entity' }
        its(:exit_status) { is_expected.to eq 0 }
      end
    end
  end
end


