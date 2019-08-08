require 'spec_helper'

# based on https://dev.mysql.com/doc/mysql-shell/8.0/en/
context 'MYSQL shell' do

  user = 'root'
  password = 'root'
  query = 'select * from db;'

  # setup for Debian based Linux is covered in
  # https://dev.mysql.com/doc/mysql-shell/8.0/en/mysql-shell-install-linux-quick.html
  # https://dev.mysql.com/doc/mysql-apt-repo-quick-guide/en/#apt-repo-setup
  # repository https://dev.mysql.com/downloads/file/?id=487007
  # https://dev.mysql.com/get/mysql-apt-config_0.8.13-1_all.deb
  # dpki -i mysql-apt-config_0.8.13-1_all.deb
  # enable "Tools and Utilities" and configure it
  # apt-get update
  # apt-get install mysql-shell
  # apt-get remove mysql-community-server mysql-community-client; apt-get install mysql-community-server mysql-community-client

  # https://stackoverflow.com/questions/39281594/error-1698-28000-access-denied-for-user-rootlocalhost

  # NOTE: there are login errors after default install,
  # TODO: those solvable through tweaking the authentication plugins and credentials
  # combined, the commands below work, alone, the first two do not reset auth plugin properly.
  #
  # USE mysql;UPDATE user SET plugin='mysql_native_password' WHERE User='#{user}'; FLUSH PRIVILEGES; exit;
  # USE mysql; CREATE USER 'vagrant'@'%' IDENTIFIED BY 'vagrant';GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'%'; UPDATE user SET plugin='auth_socket' WHERE User='vagrant'; FLUSH PRIVILEGES; exit;
  # USE mysql; UPDATE user set authentication_string=PASSWORD('#{password}') where user='#{user}';FLUSH PRIVILEGES;exit;
  # chown -R vagrant ~vagrant/.mylogin.cnf
  # chown -R vagrant ~vagrant/.mysqlsh

  # https://dev.mysql.com/doc/mysql-shell/8.0/en/mysqlsh-command.html

  context 'packages' do
    [
      'mysql-community-release'
    ].each do |package_name|
      describe package package_name do
        it { should_not be_installed }
      end
    end
    [
      'mysql80-community-release',
      'mysql-shell'
    ].each do |package_name|
      describe package package_name do
        it { should be_installed }
      end
    end

  end
  context 'plain SQL' do
    describe command <<- EOF
      mysqlsh -u '#{user}' -p'#{password}' -h localhost -P 3306 -D mysql --sql -e '#{query}'
    EOF
    do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
      [
        %w|Host Db User Select_priv Insert_priv Update_priv|,
        %w|localhost sys mysql.sys|, # fragment of the output row
      ].each do |row|
        its(:stdout) { should match Regexp.new(row.join('\s*'), Regexp::IGNORECASE) }
      end
    end
  end

  context 'plain SQL, JSON-formatted report' do
    describe command <<- EOF
      mysqlsh -u '#{user}' --password='#{password}' -h localhost -P 3306 -D mysql --json=pretty --sql -e '#{query}' |jq '.rows[0]'
    EOF
    do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
      {
        'Host' => 'localhost',
        'Db' => 'performance_schema',
        'User' => 'mysql.session',
      }.each do |key,val|
        its(:stdout) { should match Regexp.new("\\"#{key}\\":\\s+\\"#{val}\\"", Regexp::IGNORECASE) }
      end
    end
  end

  context 'Javascript with straight SQL inside' do
    describe command <<- EOF
      mysqlsh -u '#{user}' -p'#{password}' -h localhost -P 3306 -D mysql --js -e "var session = mysql.getSession({host: 'localhost', port: 3306, user: 'root', password: 'root'} ) ; session.runSql('use mysql');var results = session.runSql('select * from db;') ; var row = results.fetchOneObject(); print(row);" | jq '.["User","Host", "Db"]'
    EOF
    do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
      [
        'mysql.session',
        'localhost',
        'performance_schema',
      ].each do |val|
        its(:stdout) { should match Regexp.new("\\"#{val}\\"", Regexp::IGNORECASE) }
      end
    end
  end
  context 'Javascript query script' do

    queryfile = '/tmp/query.json'

    before(:each) do
      # NOTE: quotes
      Specinfra::Runner::run_command( <<-EOF
        cat <<END>#{datafile}
          var resultSet = mySession.runSql("select * from db where db = 'performance_schema'");
          var row = resultSet.fetchOneObject();
          print(row['Host']);
       EOF
      )
    end
    describe command <<- EOF
      mysqlsh -u '#{user}' -p'#{password}' -h localhost -P 3306 -D mysql --js < '#{queryfile}'
    EOF
    do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
      its(:stdout) { should contain 'localhost' }
    end
  end
  # TODO: reconfigure to listen to MYSQLX port:
  # var mysqlx = require('mysqlx'); var mySession = mysqlx.getSession( {host: 'localhost', port: 33060, user: 'root', password: 'root'} );
  # Connection refused connecting to localhost:33060 (MySQL Error 2002)
  # https://dev.mysql.com/doc/x-devapi-userguide/en/working-with-collections-basic-crud.html
end