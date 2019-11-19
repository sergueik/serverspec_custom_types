require 'spec_helper'

# https://www.sqlitetutorial.net/sqlite-import-csv/
# (geany:19574): Geany-WARNING **: 13:14:19.096: Geany tried to access the Unix Domain socket of another instance running as another user.
context 'collapsing colums' do
  data_file = '/tmp/stat.csv'
  # no blank rows allowed:
  # expected 3 columns but found 1 - filling the rest with NUL
  data_content=<<-EOF
    device,status,date
    google,false,2017-11-17
    apple,false,2017-11-17
    microsoft,true,2017-11-17
    google,true,2018-11-18
    apple,false,2018-11-18
    microsoft,true,2018-11-18
    google,true,2019-11-19
    apple,true,2019-11-19
    microsoft,true,2019-11-19
  EOF
  sql_file = '/tmp/sql.txt'
  sql_script = <<-EOF
    .mode csv
    .import #{data_file} stat
    .schema stat
     select x.status as apple, y.status as microsoft,z.status as microsoft, x.date from  stat x join stat y on x.date=y.date join stat z on z.date=x.date  where x.device = 'apple' and y.device='google' and z.device='microsoft' group by x.date ;
    drop table stat; 
    .quit
  EOF
  
  before(:all) do
    $stderr.puts "Writing #{data_file}"
    file = File.open(data_file, 'w')
    # csv data is leading whitespace sensitive
    file.puts data_content.gsub(/^\s+/,'')
    file.close
    $stderr.puts "Writing #{sql_file}"
    file = File.open(sql_file, 'w')
    # SQLite script is leading whitespace sensitive
    file.puts sql_script.gsub(/^\s+/,'')
    file.close
  end
  line = '(?:false|true),(?:false|true),(?:false|true),(?:\d+\-\d+\-\d+)'
  describe command( <<-EOF
    sqlite3 < '#{sql_file}'
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match Regexp.new(line) }
    its(:stderr) { should be_empty }
  end
end
