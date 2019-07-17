require 'json'

data = []
row = {}

line_num= 0
input_file =  'test.csv'
output_file = 'report.json'

File.open(input_file).each do |line|
  line.chomp!
  row = {}
  columns = line.split /\s*,\s*/
  row[:id] = columns[0]
  row[:name] = columns[1]
  row[:plays] = columns[2]
  if $DEBUG
    $stderr.print "#{line_num += 1} #{line}"
  end
  data.push row
end

begin
if $DEBUG 
  puts JSON.generate(data)
end
File.write(output_file, JSON.generate(data))
rescue => e
  $stderr.puts e.to_s
end

# /c/tools/jq-win64.exe  '.' < report.json
# [
#   {
#     "id": "1",
#     "name": "george harrison",
#     "plays": "guitar"
#   },
#   {
#     "id": "2",
#     "name": "ringo starr",
#     "plays": "drums"
#   },
#   {
#     "id": "3",
#     "name": "john lennon",
#     "plays": "guitar"
#   },
#   {
#     "id": "4",
#     "name": "paul mccartney",
#     "plays": "vocals"
#   }
# ]
# 
# 