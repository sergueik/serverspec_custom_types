require 'spec_helper'

context 'Examine result of Puppet apply resource run' do

  base_dir = '/tmp'
  list_of_dirs = %w|dir1 dir2|
  
  before(:each) do
    ruby_script = <<-EOF
      require 'fileutils'
      list_of_dirs = #{list_of_dirs}
      base_dir = "#{base_dir}"
      list_of_dirs.each do |dirname|
        dirpath = "\#{base_dir}/\#{dirname}"          
        FileUtils.mkdir_p(dirpath) unless File.exists?(dirpath)
      end
    EOF
    Specinfra::Runner::run_command( <<-EOF
      > /tmp/ruby_script.rb echo '#{ruby_script}'
      ruby -e '#{ruby_script}'
    EOF
    )
  end
  target_dir = "#{base_dir}/#{list_of_dirs[0]}"
  puppet_manifest = <<-EOF
    exec {'command with condiion':
      command  => 'echo Done',
      provider => shell,
      logoutput => true,
      onlyif   => 'test -e "#{target_dir}" && ! test -L "#{target_dir}"',
    }
  EOF
  # NOTE: To be able run Puppet in clean ruby-less uru enviroment, 
  # needed to install running one time from within uru:
  # uru gem install nokogiri
  describe command( <<-EOF
    puppet apply -e "#{puppet_manifest.gsub(/\n/, '').gsub(/\s+/, ' ')}"
    find #{base_dir} -maxdepth 1 -type d
  EOF
) do
    its(:stderr) { should be_empty }
    # to make rspec show the actual output, make the expectation unrealistic
    its(:stdout) { should include 'Done' }
    its(:stdout) { should include 'Exec[command with condiion]/returns: Done' }
    its(:exit_status) {should eq 0 }
  end
  context 'test 2' do
    base_dir = '/tmp'
    list_of_dirs = %w|dir1 dir2|
    
    before(:each) do
      ruby_script = <<-EOF
        require 'fileutils'
        list_of_dirs = #{list_of_dirs}
        base_dir = "#{base_dir}"
        list_of_dirs.each do |dirname|
          dirpath = "\#{base_dir}/\#{dirname}"          
          FileUtils.mkdir_p(dirpath) unless File.exists?(dirpath)
        end
      EOF
      Specinfra::Runner::run_command( <<-EOF
        > /tmp/ruby_script.rb echo '#{ruby_script}'
        ruby -e '#{ruby_script}'
      EOF
      )
    end
    target_dir = "#{base_dir}/#{list_of_dirs[0]}"
    puppet_manifest = <<-EOF
      \\$target_dir = '#{target_dir}'; exec {\\"command with condition for \\${target_dir}\\":
        command  => 'echo Done',
        provider => shell,
        logoutput => true,
        onlyif   => \\"test -e \\${target_dir} && ! test -L \\${target_dir}\\",
      }
    EOF
    # NOTE:  over escaping will turn a success int failure
    #    onlyif   => \\"test -e \\\\\\${target_dir} && ! test -L \\\\\\${target_dir}\\",
    # NOTE: To be able run Puppet in clean ruby-less uru environment, 
    # needed to install running one time from within uru:
    # uru gem install nokogiri
    describe command( <<-EOF
      puppet apply -e "#{puppet_manifest.gsub(/\n/, '').gsub(/\s+/, ' ')}"
      # 
      # find #{base_dir} -maxdepth 1 -type d
    EOF
  ) do
      its(:stderr) { should be_empty }
      its(:stdout) { should include 'Done' }
      its(:stderr) { should_not include 'Could not parse for environment production' }
      its(:stdout) { should match /Exec\[command with condition for .*\]\/returns: Done/ }
      its(:exit_status) {should eq 0 }
    end
    # Error: Could not parse for environment production: Syntax error at end of file on node linux.example.com
    # highty fragile
    # puppet apply -e "\$x = 1; exec {\"command with condition for \${x}\": command => 'echo Done', provider => shell, logoutput => true, onlyif => 'test -e \"/tmp/dir1\" && ! test -L \"/tmp/dir1\"', }"
    # puppet apply -e "\$target_dir = '1'; exec {\"command with condition for \${target_dir}\": command => 'echo Done', provider => shell, logoutput => true, onlyif => 'test -e \"/tmp/dir1\" && ! test -L \"/tmp/dir1\"', }"
    # puppet apply -e "\$target_dir = '/tmp/dir1'; exec {\"command with condition for \${target_dir}\": command => 'echo Done', provider => shell, logoutput => true, onlyif => 'test -e \"\${target_dir}\" && ! test -L \"/tmp/dir1\"', }"
    # puppet apply -e "\$target_dir = '/tmp/dir1'; exec {\"command with condition for \${target_dir}\": command => 'echo Done', provider => shell, logoutput => true, onlyif => 'test -e \"\${target_dir}\" && ! test -L \"\${target_dir}\"', }"
    # puppet apply -e "\$target_dir = '/tmp/dir1'; exec {\"command with condition for \${target_dir}\": command => 'echo Done', provider => shell, logoutput => true, onlyif => \"test -e \\\"\${target_dir}\\\" && ! test -L \\\"\${target_dir}\\\"\", }"
  end  
end
