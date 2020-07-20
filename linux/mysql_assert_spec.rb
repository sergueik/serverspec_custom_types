# NOTE: this logic not correct under uru
if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

context 'Assert tests' do
  # https://stackoverflow.com/questions/3560149/assertion-in-mysql
  # assign to one of MySQL global vars with predefined set of values to produce  compact one-line assertion
  # https://dev.mysql.com/doc/refman/8.0/en/sql-mode.html
  context 'MySQL' do
    sql = <<-EOF
      use information_schema;
      select count(1) from character_sets where character_set_name = 'utf8' limit 1 into @check_variable;
      SET SESSION sql_mode = IF(@check_variable, @@SESSION.sql_mode, 'assert failed');
      SET @MESSAGE = IF(@check_variable, 'assert passed', 'assert failed');
      SELECT @MESSAGE;
      select count(1) from character_sets where character_set_name = 'utf7' limit 1 into @check_variable;
      SET SESSION sql_mode = IF(@check_variable, @@SESSION.sql_mode, 'assert failed');
      SET @MESSAGE = IF(@check_variable, 'assert passed', 'assert failed');
      SELECT @MESSAGE;
      select count(1) from character_sets where character_set_name = 'utf16' limit 1 into @check_variable;
      SET SESSION sql_mode = IF(@check_variable, @@SESSION.sql_mode, 'assert failed');
    EOF
    sql.gsub!(/$/, ' ').gsub!(/  +/, ' ')
    describe command(<<-EOF
      TEMP_FILE="/tmp/a.$$.sql"
      echo "#{sql}" > $TEMP_FILE
      mysql --silent -e "source $TEMP_FILE"
    EOF
    ) do
      its(:stdout) { should contain 'assert passed' }
      its(:stdout) { should contain 'assert failed' }
      its(:stderr) { should_not be_empty }
      its(:stderr) { should contain 'ERROR 1231' }
    end
  end
end

