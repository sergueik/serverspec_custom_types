require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'date'

context 'MySQL' do

  context 'Timediff' do
    start_date = '2019-10-23 10:59:32.000'
    end_date = '2019-10-23 11:00:29.000'

    sql = <<-EOF
      use test;
      SET @start_date = CAST('#{start_date}' AS DATETIME);
      SET @end_date = CAST('#{end_date}' AS DATETIME);
      DROP TABLE IF EXISTS example;
      CREATE TABLE IF NOT EXISTS example (
        start_date DATETIME NOT NULL,
        end_date DATETIME NOT NULL
      );
      INSERT INTO example (start_date, end_date) values (@start_date, @end_date);
      SELECT start_date - end_date AS incorrect_diration FROM example;
      SELECT TIME_TO_SEC(TIMEDIFF(end_date, start_date)) AS correct_duration FROM example;
    EOF
    sql.gsub!(/$/, ' ').gsub!(/  +/, ' ')
    describe command(<<-EOF
      mysql --silent -e "#{sql}"
    EOF
    ) do
      # in Ruby attempt to substract also appears erroneous
      $stderr.puts (DateTime.parse(end_date) - DateTime.parse(start_date))
      duration = (DateTime.parse(end_date).strftime('%s').to_i - DateTime.parse(start_date).strftime('%s').to_i)
      its(:sstdout) { should contain -4097 } # no idea how MySQL does this
      its(:stdout) { should contain 57 }
      its(:stdout) { should contain duration }

    end
  end
end
