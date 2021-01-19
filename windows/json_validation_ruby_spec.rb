require_relative '../windows_spec_helper'
require 'pp'
require 'json'


# basic json syntax validation for 'jq' environment lacking
context 'json valiation' do
  datafile = 'example.json'
  datafile_path =  "#{ENV['TEMP']}/#{datafile}"
  json_data = <<-EOF
    {"id":"1","name":"test","value":true}
  EOF
  # NOTE need to escape the # in #{}
  # to defer it to be interpereted by the generated Ruby script
  # NOTE: need to prepend ruby command with uru_rt launcher to i
  # allow running this snippet in a ruby-sane environment
  describe command (<<-EOF
    $rawdata = @'
#{json_data}
'@ # end of string marker should have no indent
    write-output $rawdata |out-file '#{datafile_path}' -enc Default
    .\\uru_rt.exe ruby -rjson -e "filename = ARGV[0]; puts ('no errors in ' + File.basename(filename) ) if JSON.parse(File.read(filename))" "#{datafile_path}"
    echo $?
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain ('no errors in '+ datafile) }
  end
end