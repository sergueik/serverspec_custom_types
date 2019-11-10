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
  # pp plain_data
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
  :input   => '/tmp/data.csv',
  :cache   => '/tmp/data.json',
  # cannot use qw here - need do explicit array
  # syntax error, unexpected tIDENTIFIER, expecting keyword_do or '{' or '('
  # :columns => qw|row key value|,
  :columns => ['idx','key','value'],
  :count   => 20,
  :color   => STDOUT.tty?
}


opt.on('--logs', 'Show logs') do |val|
  @options[:logs] = val
end

opt.on('--process', 'Do some sophisticated processing') do |val|
  @options[:process] = val
end

opt.on('--cache [PATH]', 'Filepath of JSON (TODO: or XML) cache to load and to merge') do |val|
  @options[:cache] = val
end

opt.on('--input [PATH]', 'Path to the CSV file to read') do |val|
  @options[:input] = val
end

opt.on('--columns [PATH]', 'Columns of the CSV file to read') do |val|
  @options[:columns] = val.split ','
end
opt.on('--count [ROWS]', Integer, 'Number of rows to load') do |val|
  @options[:count] = val
end
opt.parse!

pp @options
csv_file_path = @options[:input]
@columns = @options[:columns]
json_file_path = @options[:cache]
$stderr.puts 'Reading ' + csv_file_path
csv_data = load_report(csv_file_path)
pp csv_data
json_data = load_cache(json_file_path)
pp json_data
merged_data = { }

merged_data  = merge_data(json_data, csv_data)
pp merged_data
