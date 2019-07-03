require 'spec_helper'
require 'fileutils'

context 'Run Ruby in RVM session' do
  tmp_path = '/tmp'
  input_file = "#{tmp_path}/MANIFEST.MF"
  # see also 
  # https://github.com/jnbt/java-properties
  # https://stackoverflow.com/questions/8485424/what-is-enumerator-object-created-with-stringgsub
  # When neither a block nor a second argument is supplied, gsub returns an enumerator.
  # https://apidock.com/ruby/Kernel/sprintf
  describe command(<<-EOF
    1>/dev/null 2>/dev/null pushd '#{tmp_path}'
    ruby  -e \\
    'fixed_lines = File.read("#{input_file}").gsub!(/\\r?\\n  */, "").split(/\\n/).each { |l| l.gsub!(/^  */, "" ) }
    properties = {}
    fixed_lines.each do |line|
      key,val = line.split /:\\s+/
      puts sprintf "%20s", key 
      properties[key] =  val
    end
    '
    1>/dev/null 2>/dev/null popd

  EOF
  ) do
    its(:exit_status) { should eq 0 }
    # its(:stderr) { should be_empty }
    %w|
      Manifest-Version
      Bnd-LastModified
      Build-Jdk
      Built-By
      Bundle-Description
      Export-Package
      Specification-Title
      Specification-Vendor
      Specification-Version
    |.each do|key|
      its(:stdout) { should contain key[0..19] }
    end  
  end
end
