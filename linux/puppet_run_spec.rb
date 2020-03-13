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
end
