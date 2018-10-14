require 'spec_helper'
require 'base64'
require 'pp'

context 'Base64 Encoded Data', :if => ENV.has_key?('URU_INVOKER') do

  context 'Standard tools' do # NOTE: not all tests will pass, exercise slightly corrupt data intentionally
    [
      # NOTE: sometimes small modifications of the input do not change result
      'Zm9vOmJhcgp=',   # foo:bar
      'Zm9vOmJhcgq=',   # foo:bar
      # 'Zm9vOmJhcaagq=', # foo:baq▒▒base64: invalid input
      # 'Zm9vOmJhcgp==',  # foo:bar base64: invalid input
      # 'Zm==',           # f
    ].each do |sample_data|
      username = 'foo'
      # NOTE: do not store password in real serverspec
      # can use regular expression to detect something that looks like a password
      password = 'bar'
      # encoded_string = base64('encode', 'foo:bar')
      encoded_string = Base64.encode64("#{username}:#{password}")
      encoded_string = sample_data
      jvm_setting = 'package.Class.method.header'
      datafile = '/tmp/sample.yaml'
      before(:each) do
        Specinfra::Runner::run_command( <<-EOF
          # indent matters
          cat <<END>#{datafile}
      -Dfile.encoding=UTF-8 -D#{jvm_setting}=#{encoded_string}
    END
      EOF
      )
      end
      # break the jvm args to single option per line and extract the encoded basic auth header
      describe command(<<-EOF
        cat '#{datafile}' | sed -e 's/\\-D/\\n/g' | sed -n 's/#{jvm_setting}=//p' | base64 -d -
      EOF
      ) do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should match Regexp.new("#{username}:.*", Regexp::IGNORECASE) }
        its(:stderr) { should_not match 'invalid input' }
      end
    end
  end

  context 'Ruby side processing' do
    [
      # NOTE: sometimes small modifications of the input do not change result
      'Zm9vOmJhcgp=',   # foo:bar
      'Zm9vOmJhcgq=',   # foo:bar
      # NOTE: some errors will go undetected, other will break report processor
      # json_formatter.rb:56:in `encode': "\xA6" from ASCII-8BIT to UTF-8 (Encoding::UndefinedConversionError)
      # 'Zm9vOmJhcaagq=', # foo:baq▒▒base64: invalid input
      'Zm9vOmJhcgp==',  # foo:bar base64: invalid input
      'Zm==',           # f
    ].each do |sample_data|
      # encoded_string = base64('encode', 'foo:bar')
      encoded_string = Base64.encode64('foo:bar')
      encoded_string = sample_data
      username = 'foo'
      jvm_setting = 'package.Class.method.header'
      command_result = command("/bin/echo '-Dfile.encoding=UTF-8 -D#{jvm_setting}=#{encoded_string}'").stdout
      answer = begin
        # extract base64auth header in jvm argument
        scan_result = command_result.scan(/(?:\-D#{jvm_setting}=)(.*)\b/i)
        PP.pp(scan_result, $stderr)
        if scan_result != []
          data = scan_result[0][0]
          $stderr.puts data
          begin
            Base64.decode64(data)
          rescue
            nil        
          end        
        else
          nil
        end
      rescue => e
        $stderr.puts e.to_s
        nil
      end
      PP.pp(answer, $stderr)

      describe String(answer) do
        it { should match Regexp.new("#{username}:.*", Regexp::IGNORECASE) }
      end
    end
  end
end