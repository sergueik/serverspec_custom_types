require 'spec_helper'

# https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html
context 'Mysql Query midnight calculations' do
  mysql_user = 'root'
  db = 'test'
  query = <<-EOF
    SELECT CURRENT_TIMESTAMP() INTO @date_var;
    SELECT
      SUBDATE(CONCAT(YEAR(@date_var), '/', MONTH(@date_var), '/', DAY(@date_var),' ' ,'23:59:00'), 0) INTO @midnight_var;
    SELECT
      @date_var as '',
      @midnight_var as '',
      DATEDIFF(@midnight_var , @date_var) as '',
      TIMESTAMPDIFF(HOUR, @midnight_var , @date_var) as '';
  EOF
  describe command(<<-EOF
    mysql -D '#{db}' -u #{mysql_user} -e "#{query.gsub(/\r?\n/, '')}"
  EOF
  ), Specinfra::Runner::run_command("ps ax | grep mysq[l]").exit_status.eql?(0) do
    its(:stdout) { should contain /\d+\-\d+\-\d+\s+\d+:\d+:\d+/ }
  end
end