require 'spec_helper'

context 'MYSQL shell' do

  user = 'root'
  password = 'root'
  # setup https://dev.mysql.com/doc/mysql-apt-repo-quick-guide/en/#apt-repo-setup
  # repository https://dev.mysql.com/downloads/file/?id=487007
  # https://dev.mysql.com/get/mysql-apt-config_0.8.13-1_all.deb
  # dpki -i mysql-apt-config_0.8.13-1_all.deb
  # enable "Tools and Utilities" and configure it
  # apt-get update
  # apt-get install -qqy mysql-shell
  # apt-get remove -qqy mysql-server; apt-get remove -qqy mysql-community-client ; apt-get install mysql-community-server  mysql-server  mysql-community-client

  # https://stackoverflow.com/questions/39281594/error-1698-28000-access-denied-for-user-rootlocalhost


  # TODO: combined, the commands below work, alone, the first two do not reset auth plugin properly.
  #
  # mysql -e "USE mysql;UPDATE user SET plugin='mysql_native_password' WHERE User='#{user}'; FLUSH PRIVILEGES; exit;"
  # mysql -e "USE mysql; CREATE USER 'vagrant'@'%' IDENTIFIED BY 'vagrant';GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'localhost'; UPDATE user SET plugin='auth_socket' WHERE User='vagrant'; FLUSH PRIVILEGES;exit;"
  # mysql -e "USE mysql; UPDATE user set authentication_string=PASSWORD('#{password}') where user='#{user}';FLUSH PRIVILEGES;exit;"
  # sudo chown -R vagrant:vagrant /home/vagrant/.mylogin.cnf
  # sudo chown -R vagrant /home/vagrant/.mysqlsh

  # https://dev.mysql.com/doc/mysql-shell/8.0/en/mysqlsh-command.html

  # a.k.a \sql ...

  query = 'select * from db;'
  describe command <<- EOF
    mysqlsh -D mysql -u '#{user}' -p'#{password}' -h localhost -P 3306 --sql -e '#{query}'
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
  describe command <<- EOF
    mysqlsh -D mysql -u '#{user}' --password='#{password}' --json=pretty -h localhost -P 3306 --sql -e '#{query}' |jq '.rows[0]'
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
  describe command <<- EOF
    mysqlsh  -u root -p'root' -h localhost -P 3306 --js   -e "var session = mysql.getSession({host: 'localhost', port: 3306, user: 'root', password: 'root'} ) ; session.runSql('use mysql');var results = session.runSql('select * from db;') ; var row = results.fetchOneObject(); print(row);" | jq '.["User","Host", "Db"]'
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