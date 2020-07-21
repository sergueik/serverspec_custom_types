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
  # https://dev.mysql.com/doc/refman/5.7/en/sql-mode.html
  # https://dev.mysql.com/doc/refman/5.7/en/server-system-variable-reference.html
  # https://dev.mysql.com/doc/refman/5.7/en/show-variables.html
  # NOTE: cannot use just any variable, e.g. @@SESSION.old
  
  context 'MySQL' do
    context 'Passing assertion' do
      sql = <<-EOF
        use information_schema;
        select count(1) from character_sets where character_set_name = 'utf8' limit 1 into @check_variable;
        SET SESSION sql_mode = IF(@check_variable, @@SESSION.sql_mode, 'assert failed');
        SELECT character_set_name from character_sets where character_set_name = 'utf16' limit 1 into @check_variable;
        SET @assert_failed = IF(STRCMP(@check_variable,'utf16') <> 0,  true, false);
        SET SESSION sql_mode = IF(@assert_failed, 'assert failed', @@SESSION.sql_mode);
        SET SESSION sql_mode = IF(STRCMP(@check_variable,'utf16') <> 0, 'assert failed', @@SESSION.sql_mode);
      EOF
      sql.gsub!(/$/, ' ').gsub!(/  +/, ' ')
      describe command(<<-EOF
        TEMP_FILE="/tmp/a.$$.sql"
        echo "#{sql}" > $TEMP_FILE
        mysql --silent -e "source $TEMP_FILE"
        rm -f $TEMP_FILE
      EOF
      ) do
        its(:stderr) { should be_empty }        
      end
    end  
    context 'Failing assertion' do
      sql = <<-EOF
        use information_schema;
        SET SESSION sql_mode = 'some string impossible to assign';
        select count(1) from character_sets where character_set_name = 'utf7' limit 1 into @check_variable;
        SET SESSION sql_mode = IF(@check_variable, @@SESSION.sql_mode, 'assert failed');        
        SELECT character_set_name from character_sets where character_set_name = 'utf16' limit 1 into @check_variable;
        SET @assert_failed = IF(STRCMP(@check_variable,'utf17') <> 0,  true, false);
        SET SESSION sql_mode = IF(@assert_failed, 'assert failed', @@SESSION.sql_mode);
        SELECT CONCAT('ASSERT FAILED with unexpected value is ', @check_variable) INTO  @message;
        SET SESSION sql_mode = IF(STRCMP(@check_variable,'utf17') <> 0, @message, @@SESSION.sql_mode);
      EOF
      sql.gsub!(/$/, ' ').gsub!(/  +/, ' ')
      describe command(<<-EOF
        TEMP_FILE="/tmp/a.$$.sql"
        echo "#{sql}" > $TEMP_FILE
        mysql --silent -e "source $TEMP_FILE"
        rm -f $TEMP_FILE
      EOF
      ) do
        its(:stderr) { should_not be_empty }
        its(:stderr) { should contain 'ERROR 1231' }
        its(:stderr) { should contain "Variable 'sql_mode' can't be set to the value of 'some string impossible to assign'" }
        its(:stderr) { should contain 'ASSERT FAILED with unexpected value is utf16' }
        
      end
    end  
  end
end
