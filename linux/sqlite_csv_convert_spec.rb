require 'spec_helper'
# Copyright (c) Serguei Kouzmine

# https://www.sqlitetutorial.net/sqlite-import-csv/
# (geany:19574): Geany-WARNING **: 13:14:19.096: Geany tried to access the Unix Domain socket of another instance running as another user.
context 'collapsing colums' do
  data_file = '/tmp/stat.csv'
  # no blank rows allowed:
  # expected 3 columns but found 1 - filling the rest with NUL
  # in any given row, all columns (`status` and `value`) describe to the leftmost column,
  # at a specific date (the rightmost column)
  data_content=<<-EOF
    device,status,value,date
    google,false,google_value1,2017-11-17
    apple,false,apple_value1,2017-11-17
    microsoft,true,ms_value1,2017-11-17
    google,true,google_value2,2018-11-18
    apple,false,apple_value2,2018-11-18
    microsoft,true,ms_value2,2018-11-18
    google,true,google_value3,2019-11-19
    apple,true,apple_value3,2019-11-19
    microsoft,true,md_value_3,2019-11-19
  EOF

  before(:all) do
    $stderr.puts "Writing #{data_file}"
    file = File.open(data_file, 'w')
    # csv data is leading whitespace sensitive
    file.puts data_content.gsub(/^\s+/,'')
    file.close
  end
  context 'minimal example' do
    sql_file = '/tmp/sql1.txt'
    sql_script = <<-EOF
      .mode csv
      .import #{data_file} stat
      .schema stat
      select
        google_rows.status as google_status,
        apple_rows.status as apple_status,
        ms_rows.status as microsoft_status,
        ms_rows.date
      from
        stat apple_rows
      join
        stat google_rows
      on
        apple_rows.date = google_rows.date
      join
        stat ms_rows
      on
        ms_rows.date = google_rows.date
      where
        apple_rows.device = 'apple'
      and
        google_rows.device = 'google'
      and
        ms_rows.device = 'microsoft'
      group by
        apple_rows.date;
      drop table stat;
      .quit
    EOF

    line = '(?:false|true),(?:false|true),(?:false|true),(?:\d+\-\d+\-\d+)'
    before(:all) do
      $stderr.puts "Writing #{sql_file}"
      file = File.open(sql_file, 'w')
      # SQLite script is leading whitespace sensitive
      file.puts sql_script.gsub(/^\s+/,'')
      file.close
    end
    describe command( <<-EOF
      sqlite3 < '#{sql_file}'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match Regexp.new(line) }
      its(:stderr) { should be_empty }
    end
  end
  context 'multi value column example' do
    sql_file = '/tmp/sql2.txt'
    sql_script = <<-EOF
      .mode csv
      .import #{data_file} stat
      .schema stat
      select
        google_rows.status as google_status,
        apple_rows.status as apple_status,
        ms_rows.status as microsoft_status,
        google_rows.value as google_value,
        apple_rows.value as apple_value,
        ms_rows.value as microsoft_value,
        ms_rows.date
      from
        stat apple_rows
      join
        stat google_rows
      on
        apple_rows.date = google_rows.date
      join
        stat ms_rows
      on
        ms_rows.date = google_rows.date
      where
        apple_rows.device = 'apple'
      and
        google_rows.device = 'google'
      and
        ms_rows.device = 'microsoft'
      group by
        apple_rows.date;
      drop table stat;
      .quit
    EOF

    line = '(?:false|true),(?:false|true),(?:false|true),google_value\d+,apple_value\d+,ms_value\d+,(?:\d+\-\d+\-\d+)'
    before(:all) do
      $stderr.puts "Writing #{sql_file}"
      file = File.open(sql_file, 'w')
      # SQLite script is leading whitespace sensitive
      file.puts sql_script.gsub(/^\s+/,'')
      file.close
    end
    describe command( <<-EOF
      sqlite3 < '#{sql_file}'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match Regexp.new(line) }
      its(:stderr) { should be_empty }
    end
  end
end

