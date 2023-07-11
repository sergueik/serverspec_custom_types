# https://database.guide/json_search-find-the-path-to-a-string-in-a-json-document-in-mysql/
# Copyright (c) Serguei Kouzmine
# https://www.baeldung.com/java-in-memory-databases

# NOTE: need MySQL 8.x 
# 5.x fail with FUNCTION JSON_SEARCH does not exist

context 'MySQL' do
  locahost = '127.0.0.1'
  port = 3306
  user = 'java'
  password = 'password'
  result = '\$.Bart'
  context 'JSON Search'  do
    describe command(<<-EOF
      mysql -b -P #{port} -h 127.0.0.1 -u #{user} -p#{password} -e "set @doc = '{\\"Bart\\": \\"Simpson\\"}';  SELECT JSON_SEARCH(@doc, 'one', 'Simpson') Result;"
    EOF
    ) do
    [
      'test',
     # 'db name',
    ].each do |db|
        its(:stdout) { should contain(result) }
        its(:stderr) { should be_empty }
      end
    end
  end
end
