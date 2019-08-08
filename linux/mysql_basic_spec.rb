require 'spec_helper'

context 'MySQL' do

  context 'DB'  do
    describe command(<<-EOF
      mysql -e 'SELECT DISTINCT DB FROM mysql.db;'
    EOF
    ) do
    [
      'test',
     # 'db name',
    ].each do |db|
        its(:stdout) { should contain(db) }
      end
    end
  end

  context 'Databases' do
    {
    'test' => %w|
                  information_schema
                  test
                |,
    }.each do |db,databases|
      describe command(<<-EOF
        mysql -D '#{db}' -e 'show databases;'
      EOF
      ) do
        databases.each do |database_name|
          its(:stdout) { should contain database_name }
        end
      end
    end
  end

  context 'Users' do
    mysql_user = 'root'
    db = 'test'
    describe command(<<-EOF
      mysql -D '#{db}' -u #{mysql_user} -e 'SELECT User FROM mysql.user;'
    EOF
    ) do
      [
        'root@localhost',
      ].each do |user_name|
        its(:stdout) { should contain user_name.gsub(/@.+$/,'') }
      end
    end
  end

  context 'Indexes' do
    # origin: https://stackoverflow.com/questions/5213339/how-to-see-indexes-for-a-database-or-table
    query1=<<-EOF
      SELECT TABLE_NAME,
        COUNT(1) index_count,
        GROUP_CONCAT(DISTINCT(index_name) SEPARATOR ',\\n ') indexes
      FROM INFORMATION_SCHEMA.STATISTICS
      WHERE
        TABLE_SCHEMA = 'mysql'
        AND
        INDEX_NAME != 'primary'
      GROUP BY TABLE_NAME
      ORDER BY COUNT(1) DESC;
    EOF
    query1.gsub!(/$/, ' ').gsub!(/  +/, ' ')
    {
    # the example lists the expected indexes and tables together
    'mysql' =>
      %w|
          help_category
          name
          help_keyword
          name
        |,
    }.each do |db,database_or_index_columns|
      describe command(<<-EOF
        mysql -D '#{db}' -e "#{query1}"
      EOF
      ) do
        database_or_index_columns.each do |database_or_index_name|
          its(:stdout) { should contain database_or_index_name }
        end
      end
    end
    query2 =<<-EOF
      SELECT TABLE_NAME, TABLE_SCHEMA, INDEX_NAME from (
      SELECT DISTINCT s.* FROM INFORMATION_SCHEMA.STATISTICS s LEFT OUTER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS t
      ON t.TABLE_SCHEMA = s.TABLE_SCHEMA
      AND t.TABLE_NAME = s.TABLE_NAME
      AND s.INDEX_NAME = t.CONSTRAINT_NAME
      WHERE 0 = 0
      AND t.CONSTRAINT_NAME IS NULL
      ) x;
    EOF
    query2.gsub!(/$/, ' ').gsub!(/  +/, ' ')
    {
    # the example lists the expected indexes and tables together
    'mysql' =>
      %w|
          tables_priv
          Grantor
          proxies_priv
          Grantor
        |,
    }.each do |db,database_or_index_columns|
      describe command(<<-EOF
        mysql -D '#{db}' -e "#{query2}"
      EOF
      ) do
        database_or_index_columns.each do |database_or_index_name|
          its(:stdout) { should contain database_or_index_name }
        end
        report_line = 'TABLE_NAME TABLE_SCHEMA INDEX_NAME'
        its(:stdout) { should contain Regexp.new('^\s*' + report_line.strip.gsub!(/ +/, '\s+') + '\s*$', Regexp::IGNORECASE) }
      end
    end
    # In a real world scenario one get the following output
    #   TABLE_NAME TABLE_SCHEMA INDEX_NAME
    #   API        WSO2_API     API_ID
    #   API_SCOPES WSO2_API     API_ID
    #   API_SCOPES WSO2_API     SCOPE_ID
    #   ...
    # with the indexes often named same for different tables
    {
    'WSO2_API' =>
      %w|
          TABLE_NAME TABLE_SCHEMA INDEX_NAME
          API        WSO2_API     API_ID
          API_SCOPES WSO2_API     API_ID
          API_SCOPES WSO2_API     SCOPE_ID
        |,
    }.each do |db,report_lines|
      user = 'database_user'
      password = 'database_user_password'
      describe command(<<-EOF
        mysql -u #{user} -p'#{password}' -D '#{db}' -e "#{query2}" | tee '/tmp/query_result.txt'
      EOF
      ) do
        report_lines.each do |report_line|
          # including leading / trailing whitespace in match pattern is optional
          # uncomment after providing reasonable inputs to database user identity
          # its(:stdout) { should contain Regexp.new('^\s*' + report_line.strip.gsub!(/ +/, '\s+') + '\s*$', Regexp::IGNORECASE) }
        end
      end
    end
  end

  # NOTE: there may be inconsistency between the actual datadir and contents of '/etc/my.cnf'
  context 'Datadir' do
    custom_datadir = '/opt/mysql/var/lib/mysql/'
    # NOTE: not every flag is really necessary: silent, batch, vertical column, execute and quit
    # the correct flags are -NBe
    describe command(<<-EOF
      mysql -sBEe 'select @@datadir;'
      mysql -NBe 'select @@datadir;'
    EOF
    ) do
      its(:exit_status) {should eq 0 }
      its(:stdout) { should match /@@datadir: #{custom_datadir}/i }
      its(:stdout) { should match custom_datadir }
    end

    # NOTE trailing slash processing
    default_datadir = '/var/lib/mysql'
    default_datadir = custom_datadir.gsub(/\/$/,'')
    custom_datadir = '/opt/mysql/var/lib/mysql'
    describe command(<<-EOF
      echo $(mysql -sBEe 'select @@datadir;' | awk '/@@datadir/ {print $2}' | sed 's|/$||')
      readlink $(mysql -sBEe 'select @@datadir;' | awk '/@@datadir/ {print $2}' | sed 's|/$||')
    EOF
    ) do
      its(:exit_status) {should eq 0 }
      its(:stdout) { should match default_datadir }
      its(:stdout) { should match custom_datadir }
    end

  end

  # NOTE: this may fail on a vanilla db
  context 'Grants' do
    {
      'privileged_user@%' => '*.*',
      'root@localhost'    => '*.*'
    }.each do |account,db|

      user, host, *rest  = account.split(/@/)
      describe command(<<-EOF
        mysql -e 'SHOW GRANTS FOR "#{user}"@"#{host}"'
      EOF
      ) do
        its(:exit_status) {should eq 0 }
        its(:stdout) { should match /GRANT ALL PRIVILEGES ON *.* TO '#{user}'@'#{host}'/i }
        its(:stderr) { should_not match /There is no such grant defined for user '#{user}' on host '#{host}'/i }
      end
    end
    user = 'none'
    host = 'localhost'
    describe command(<<-EOF
      mysql -e 'SHOW GRANTS FOR "#{user}"@"#{host}"'
    EOF
    ) do
      its(:stderr) { should match /There is no such grant defined for user '#{user}' on host '#{host}'/i }
    end
  end
  # see https://toster.ru/q/620562
  context 'Socket and configuration' do
    mysql_cnf = '/etc/my.cnf'
    root_mysql_cnf = '/root/.my.cnf'
    describe command(<<-EOF
      stat $(grep socket '#{mysql_cnf}' | head -1 | sed 's/socket=//')
      stat $(grep -Po 'socket=.*' '#{root_mysql_cnf}' | head -1 | sed 's/socket=//)
      stat $(sed -n '/socket=\\(.*\\)/{s//\\1/p;q}' '#{root_mysql_cnf}')
    EOF
    ) do
      its(:stdout) { should match /socket$/ }
    end
  end
  context 'Stale socket discovery' do
    mysql_server = 'mysqld'
    socket_filename = 'mysql.sock'
    socket_path = '/var/lib/mysql'
    # NOTE: recent versions of lsof are helpful in this topic
    # see also https://unix.stackexchange.com/questions/16300/whos-got-the-other-end-of-this-unix-socketpair
    describe command(<<-EOF
      lsof -c '#{mysql_server}'| grep 'unix' | grep  '#{socket_filename}')
    EOF
    ) do
      its(:exit_status) {should eq 0 }
      its(:stdout) { should match /\b#{socket_path}\// }
    end
  end
  context 'Galera bootstrap' do

    service_name = 'mysqld'
    # galera bootstrap uses rare systemd feature of custom namin for service
    # 'mysql@bootstrap.service'
    # implemented through files like /usr/lib/systemd/system/mysql@.service
    # so to locate the service without knowing the exact name use the spec below
    # systemctl list-units --type=service --state=running | grep '#{name}' | awk '{print $1}'
    [
    'mysql',
    'mysql@',
    ].each do |name|
      describe file "/usr/lib/systemd/system/#{name}.service" do
        it { should be_file }
      end
    end
    # --output=json option has no effect
    # where a service changes to 'stopped' e.g. through Puppet
    # is will not be listed in any state, rather completely disappear
    describe command(<<-EOF
      systemctl list-units --type=service --state=running
    EOF
    ) do
      its(:exit_status) {should eq 0 }
      its(:stdout) { should match /\b#{service_name}(?:@bootstrap)?\.service\b/ }
    end
  end
end
