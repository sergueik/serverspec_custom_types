require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'pp'
require 'json'


# basic json syntax validation for 'jq' environment lacking
context 'json valiation' do
  datafile = '/tmp/example.json'
  before(:each) do
    # NOTE: indent and white space matters
    Specinfra::Runner::run_command( <<-EOF
      cat<<END>'#{datafile}'
	{"id":"1","name":"test","value":true}
    EOF
    )
  end # NOTE need to escape the # in #{} 
  # to defer it to be interpereted by the generated Ruby script
  # NOTE: need to prepend ruby command with uru_rt launcher to i
  # allow running this snippet in a ruby-sane environment
  describe command(<<-EOF
    NAME='#{datafile}'
    RUBY='ruby'
    if [ ! -z  $URU_INVOKER ]; then RUBY='/uru/uru_rt ruby' ; fi
    $RUBY -rjson -e 'filename = ARGV[0]; puts "no errors in \#{filename}" if JSON.parse(File.read(filename))' $NAME
    echo $?
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain ('no errors in '+ datafile) }
  end
  # NOTE: combining postfix notation with for ... end 
  describe command(<<-EOF
    NAME='#{datafile}'
    RUBY='ruby'
    if [ ! -z  $URU_INVOKER ]; then RUBY='/uru/uru_rt ruby' ; fi
    $RUBY -rjson -e 'files = [];for arg in ARGV ; filename = arg; files.append filename if JSON.parse(File.read(filename));end; print "no errors in \#{files}"; ' $NAME $NAME
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match ('no errors in ["/tmp/example.json", "/tmp/example.json"]' ) }
    its(:stdout) { should match ("no errors in \[\"#{datafile}\", \"#{datafile}\"\]") }
  end
end
