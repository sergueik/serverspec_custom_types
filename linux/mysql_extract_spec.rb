require 'spec_helper'

context 'Mysql' do
  # https://stackoverflow.com/questions/16711598/get-the-sql-query-result-without-the-table-format
  # suppress default output result ascii table deconation then create on's own using CONCAT_WS
  # https://www.cyberforum.ru/shell/thread2681420-page2.html
  context 'Data extract with leading and trailing space capture' do
    describe command(<<-EOF
      IFS='^'
      mysql --batch --silent -D information_schema -e "SELECT CONCAT_WS('^', '', character_set_name, description,maxlen,'') as dummy_field from character_sets where character_set_name like 'utf%' limit 5;" |  while read a b c d;
      do
        echo "name=$b"
        echo "description=$c"
        echo "len=$d"
      done
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
      {
        'name' => 'utf16',
        'description' =>'UTF-16 Unicode'
      }.each do |key,val|
        its(:stdout) { should match /#{key}=#{val}/}
      end
    end
  end
  context 'Data extract' do
    describe command(<<-EOF
      IFS='^'
      mysql --batch --silent -D information_schema -e "SELECT CONCAT_WS('^', character_set_name, description,maxlen) as dummy_field from character_sets where character_set_name like 'utf%' limit 5;" |  while read a b c d;
      do
        echo "name=$a"
        echo "description=$b"
        echo "len=$c"
      done
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
      {
        'name' => 'utf8',
        'description' =>'UTF-8 Unicode'
      }.each do |key,val|
        its(:stdout) { should match /#{key}=#{val}/}
      end
    end
  end
end
