require 'pp'
require 'yaml'
USE_PURE_JSON_GEM = false
if  USE_PURE_JSON_GEM
  begin
    # NOTE: not json_pure
    require 'json/pure' # support no-rubydev gems
    test_pure_ruby_json = true
    # NOTE: json_pure-2.2.0/lib/json/pure/generator.rb:309:in `to_json': wrong
    # argument type JSON::Pure::Generator::State (expected JSON/Generator/State) (TypeError)
  rescue LoadError => e
    $stderr.puts ('Failed to load json_pure for JSON parsing: ' + e.to_s)
    require 'json' # allow fail with LoadError now
    test_pure_ruby_json = false
  end
else
  require 'json'
  test_pure_ruby_json = false
end
$stderr.puts ('JSON parsing in pure Ruby: ' +   test_pure_ruby_json.to_s)
require 'csv'

# use embedded XML class
# https://www.xml.com/pub/a/2005/11/09/rexml-processing-xml-in-ruby.html
require 'rexml/document'
include REXML

# origin: https://github.com/mizzy/serverspec/blob/master/lib/serverspec/type/command.rb
# monkey-patching the Command class in the uru environment
module Serverspec::Type
  class Command < Base
    def stdout
      command_result.stdout
    end

    def stdout_as_csv
      begin
        @res = CSV.parse(command_result.stdout)
        # pp @res
        @res
      rescue => e
        $stderr.puts e.to_s
        nil
      end
    end

    def stdout_as_json
      begin
        @res = JSON.parse(command_result.stdout)
        # pp @res
        @res
      rescue => e
        $stderr.puts e.to_s
        nil
      end
    end

    def stdout_as_xml
      begin
        @res = Document.new(command_result.stdout)
        # pp @res
        @res
      rescue => e
        $stderr.puts e.to_s
        nil
      end
    end

    def stdout_as_yaml
      begin
        @res = YAML.load(command_result.stdout)
        # pp @res
        @res
      rescue => e
        $stderr.puts e.to_s
        nil
      end
    end

    def stdout_as_data
      begin
        # hack around logstash logging its operations together with rubydebug output
        # NOTE: invalid multibyte char (UTF-8) (SyntaxError)
        rawdata = command_result.stdout.split(/\r?\n/).reject { |line|
          line =~ /(?:No log4j2 configuration file found|Sending Logstash's)/ ;
        }.reject { |line|
          line =~ /@timestamp/i
        }.reject {|line|
          line =~ /(?:_dateparsefailure|_grokparsefailure)/
        }
        @res = eval(rawdata.join("\n"))
        # pp @res
        @res
      rescue => e
        nil
      end
    end

    def stderr
      command_result.stderr
    end

    def exit_status
      command_result.exit_status.to_i
    end

    private
    def command_result()
      @command_result ||= @runner.run_command(@name)
    end
  end
end
