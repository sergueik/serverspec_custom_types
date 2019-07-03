require 'spec_helper'
require 'fileutils'

context 'Run Ruby in RVM session' do
  tmp_path = '/tmp'
  input_file = "#{tmp_path}/MANIFEST.MF"
  # see also 
  # https://github.com/jnbt/java-properties
  # https://stackoverflow.com/questions/8485424/what-is-enumerator-object-created-with-stringgsub
  # https://apidock.com/ruby/Kernel/sprintf
  describe command(<<-EOF
    1>/dev/null 2>/dev/null pushd '#{tmp_path}'
    ruby  -e \\
    'path = "#{input_file}"; 
    text = File.read(path)
    fixed_lines = []
    if text =~ /\\r?\\n  */ 
      $stderr.puts "raw has tbl style formatting "
    else
      $stderr.puts "does not have formatting defects"
    end 
    fixed_text = text.gsub!(/\\r?\\n  */, "")
    if fixed_text =~ /\\r?\\n  */ 
      $stderr.puts "manifest text raw has tbl style formatting "
    else
      $stderr.puts "manifest text does not have formatting defects"
    end 
    fixed_text.split(/\\n/).each do |line|
          
      line.gsub!(/^  */, "" )
      fixed_line = line.gsub(/^  */, "" )
      fixed_lines.push line
    end
    properties = {}
    fixed_lines.each do |line|
      key,val =  line.split /:\\s+/
      properties[key] =  val
    end
    properties.each do |key,val|    
      puts sprintf "%20s", key
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
