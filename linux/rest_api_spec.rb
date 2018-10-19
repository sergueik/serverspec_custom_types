require 'spec_helper'
require 'json'
require 'yaml'
require 'ostruct'

$DEBUG = true

# this example may be considered as a clean way to compose the JSON payload for consul REST API post deployment checks
# also for constructing jenkins config.xml
# https://jsonplaceholder.typicode.com/
# and https://github.com/typicode/jsonplaceholder#how-to
context 'REST API' do
  context 'JSON payoad' do
    url = 'https://jsonplaceholder.typicode.com/posts'
    rest_api_command = <<-EOF
      PAYLOAD=$(cat<<DATA| jq -c '.'
      {
        "title": "foo",
        "body": "bar",
        "userId": 1
      }
DATA
# NOTE: shoud be no space in front of the DATA marker
      )
      LOG='/tmp/a.txt'
      URL='#{url}'
      echo $PAYLOAD 1>&2
      curl -# -X POST -H 'Content-Type: application/json' -d $PAYLOAD -k $URL 2>&1 | tee $LOG
      cat '/tmp/a.txt' 1>&2
    EOF
    # the hash #
    # will be ignored by YAML
    key = 'body'
    value = 'bar'
    describe command(rest_api_command) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match Regexp.new("\"#{key}\": \".*\"", Regexp::IGNORECASE) }
      its(:stderr) { should_not match 'SyntaxError: Unexpected token - in JSON' }
    end

    rest_api_response_data = nil
    $stderr.puts 'Running the command: ' + rest_api_command if $DEBUG
    begin
      raw_response = command(rest_api_command).stdout
      $stderr.puts 'raw response: ' + raw_response if $DEBUG
    rescue => e
      # NOTE: Exception `IO::EAGAINWaitReadable in specinfra <internal:prelude>:76
      # may need to rebuild uru with a more recent specinfra
      $stderr.puts 'Exception from running the command : ' + e.to_s
    end

    $stderr.puts 'Deserializing data' if $DEBUG
    # https://stackoverflow.com/questions/6423484/how-do-i-convert-hash-keys-to-method-names
    begin
      $stderr.puts 'Trying JSON parse' if $DEBUG
      rest_api_response = JSON.parse(raw_response)
    rescue Exception => e
      $stderr.puts 'Exception from JSON: ' + e.to_s
    end

    begin
      $stderr.puts 'Trying YAML load' if $DEBUG
      rest_api_response = YAML.load(raw_response)
    rescue Exception => e
      $stderr.puts 'Exception from YAML load: ' + e.to_s
    end
    if ! rest_api_response.nil?
      $stderr.puts 'rest_api_response: ' + rest_api_response.class.name if $DEBUG
      describe 'Test' do
        subject { OpenStruct.new rest_api_response }
        its(:title) { should eq 'foo' }
        its(:body) { should match Regexp.quote('bar') }
      end
    end
  end
end