require_relative '../windows_spec_helper'

context 'Base64 data' do
  temp_path = 'C:\windows\temp'
  java_path = 'C:\java\jdk1.8.0_101'
  java_class = 'App'
  result = 'test data'
  java_source = <<-EOF
    import java.util.Base64;
    public class #{java_class} {
      public static void main(String[] args) {
        System.err
          .println("Result: " + new String(Base64.getDecoder().decode(args[0])));
      }
    }
  EOF
  context 'valid' do
    data = 'dGVzdCBkYXRhDQo='
    describe command(<<-EOF
      $data = '#{data}'
      [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($data))      
    EOF
    ) do
      its(:exit_status) { should be 0 }
      its(:stdout) { should match Regexp.new(result, Regexp::IGNORECASE) }
    end
    describe command(<<-EOF
      $java_path = '#{java_path}'
      $java_source = @'
      #{java_source}
'@
      $java_class = '#{java_class}'
      $temp_path = '#{temp_path}'
      $env:PATH = "$env:PATH;${java_path}\\bin"
      if ($temp_path -eq '') {
        $temp_path = $script_directory = [System.IO.Path]::GetDirectoryName(($MyInvocation.MyCommand.Definition -replace '\\', '\\\\'))
        # NOTE: Exception calling "GetDirectoryName" with "1" argument(s): "Illegal characters in path"
      }
      try {

        pushd $temp_path
        write-output $java_source| out-file -filepath "${java_class}.java" -encoding ASCII
        try {
          $command = "javac ${java_class}.java 2>&1"
          write-output ('Compiling Java class command: {0} in "{1}"' -f $command, $temp_path )
          $output = invoke-expression -command $command
          write-output ('java output: {0}' -f $output)
        } catch [Exception] {
          write-output (($_.Exception.Message) -split "`n")[0]
        }
        dir "${java_class}.class"
        try {
          $data = '#{data}'
          $command = "java ${java_class} $data 2>&1"
          write-output ('Running command: {0} in "{1}"' -f $command, $temp_path )
          $output = invoke-expression -command $command
          write-output ('java output: {0}' -f $output)
        } catch [Exception] {
          write-output (($_.Exception.Message) -split "`n")[0]
        }
      } catch [Exception] {
          write-output (($_.Exception.Message) -split "`n")[0]
      }
      popd
    EOF
    ) do
      let(:path) { "#{java_path}\\bin" }
      its(:stdout) { should match /#{java_class}.class/i }
      its(:exit_status) { should be 0 }
      its(:stdout) { should match Regexp.new("Result: #{result}", Regexp::IGNORECASE) }
    end
  end
  context 'invalid' do
    data = 'dGVzdCBkYXRhDQo'
    describe command(<<-EOF
      $data = '#{data}'
      try {
        [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($data))      
      } catch [Exception] { 
        write-error $_.Exception.Message
      }
    EOF
    ) do
      its(:exit_status) { should be 256 } # !!
      its(:stderr) { should match Regexp.new('Invalid length for a Base-64 char array or string.', Regexp::IGNORECASE) }
    end
    describe command(<<-EOF
      $temp_path = '#{temp_path}'
      $java_class = '#{java_class}'
      $java_source = @'
      #{java_source}
'@

      pushd $temp_path
      write-output $java_source| out-file -filepath "${java_class}.java" -encoding ASCII
      $command = "javac ${java_class}.java 2>&1"
      invoke-expression -command $command
      $data = '#{data}'
      $command = "java ${java_class} $data 2>&1"
      $output = invoke-expression -command $command
      write-output ('java output: {0}' -f $output)
    EOF
    ) do
      let(:path) { "#{java_path}\\bin" }
      its(:exit_status) { should be 0 }
      its(:stdout) { should match Regexp.new("Result: #{result}", Regexp::IGNORECASE) }
    end
  end
end

