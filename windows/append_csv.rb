# require_relative '../windows_spec_helper'
require 'csv'
require 'json'
require 'yaml'
require 'pp'
require 'optparse'

# context 'append the csv row data to json object' do
#   before(:all) do
#   end
# end

def load_report(path)
  plain_data = CSV.parse(File.read(path))
  # PP.pp plain_data, $stderr
  csv_data = []
  # do some debug logging of csv_data

  plain_data.each do |row|
    csv_data_row = {}
    row.each_with_index do |column,index|
      csv_data_row[@columns[index]] = column
    end
    if csv_data_row.has_key?('idx')
      csv_data.push csv_data_row
    end
  end
  csv_data
end

def load_cache(path)
  json_data = JSON.load(File.read(path))
  # do some debug logging of csv_data
  json_data
end

def merge_data(cache_data, input_data)
  input_data.each do |row|
    cache_data['data'].push row
  end
  cache_data
end

def report_resources(report)
  report.resource_statuses
end

opt = OptionParser.new

@options = {
  :logs    => false,
  :process => false,
  :dir     => '/tmp',
  :file    => 'data.*.csv', # passing glob
  :output  => nil,
  :cache   => '/tmp/data.json',
  # cannot use qw here - need do explicit array
  # syntax error, unexpected tIDENTIFIER, expecting keyword_do or '{' or '('
  # :columns => qw|row key value|,
  :columns => ['idx','key','value'],
  :params  => (['startdate','enddate'].join ','),
  :values  => (['11/10/2019','11/11/2019'].join ','),
  :count   => 20,
  :color   => STDOUT.tty?
}


opt.on('--logs', 'Show logs') do |val|
  @options[:logs] = val
end

opt.on('--process', 'Do some sophisticated processing') do |val|
  @options[:process] = val
end

opt.on('--params [ARRAY]', 'Names of extra params') do |val|
  @options[:params] = val
end

opt.on('--values [ARRAY]', 'Values of extra params') do |val|
  @options[:values] = val
end

opt.on('--process', 'Do some sophisticated processing') do |val|
  @options[:process] = val
end

opt.on('--cache [PATH]', 'Filepath of JSON (TODO: or XML) cache to load and to merge') do |val|
  @options[:cache] = val
end

opt.on('--dir [PATH]', 'Path to the directory containing CSV files to read') do |val|
  @options[:dir] = val
end

opt.on('--file [MASK]', 'File mask of the CSV file to read') do |val|
  @options[:file] = val
end

opt.on('--output [PATH]', 'Path to the JSON file to written') do |val|
  @options[:output] = val
end

opt.on('--columns [PATH]', 'Columns of the CSV file to read') do |val|
  @options[:columns] = val.split ','
end
opt.on('--count [ROWS]', Integer, 'Number of rows to load') do |val|
  @options[:count] = val
end
opt.parse!

PP.pp @options, $stderr
csv_file_path = @options[:input]
@columns = @options[:columns]
json_file_path = @options[:cache]
json_data = load_cache(json_file_path)
# PP.pp json_data, $stderr
merged_data = { }
datadir = @options[:dir]
datafile = @options[:file]
file_mask = datadir + '/' + datafile
Dir.glob(file_mask).each do |file_path|
  # $stderr.puts 'Reading ' + file_path
  csv_data = load_report(file_path)
  # PP.pp csv_data, $stderr
  merged_data  = merge_data(json_data, csv_data)
  # PP.pp merged_data, $stderr
  # $stderr.puts JSON.dump(merged_data)
  json_data = merged_data
end

process = @options[:process]

if process
  if ( ! @options[:params].nil? ) && ( ! @options[:values].nil? )
    params = @options[:params].split(',')
    values = @options[:values].split(',')
    # PP.pp params, $stderr
    # PP.pp values, $stderr
    params.each_with_index do |param,index|
      value = values[index]
      json_data[param] = value
    end
  end
end

# PP.pp json_data, $stderr

output_path = @options[:output]
if ! output_path.nil?
  File.open(output_path, 'w') { |f| f.write(JSON.dump(json_data)) }
end

# /tmp/data.1.csv
# 110,a1,b1
# 120,a1,d1
# /tmp/data.1.csv
# 210,a2,b2
# ./uru_rt ruby append_csv.rb --output '/tmp/new_data.json' --params 'startdate,enddate'  --values '01/01/2019,11/11/2019' --process
# jq '.' '/tmp/new_data.json'
#  {
#    "dummy": "dummy",
#    "data": [
#      {
#        "idx": -1,
#        "key": null,
#        "value": "",
#        "comment": "dummy"
#      },
#      {
#        "idx": "110",
#        "key": "a1",
#        "value": "b1"
#      },
#      {
#        "idx": "210",
#        "key": "a2",
#        "value": "b2"
#      },
#      {
#        "idx": "220",
#        "key": "a2",
#        "value": "b2"
#      }
#    ],
#  "startdate": "01/01/2019",
#  "enddate": "11/11/2019"
#
#  }
#
