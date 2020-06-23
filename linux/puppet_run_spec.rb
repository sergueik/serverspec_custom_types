require 'spec_helper'

context 'Examine result of Puppet apply resource run' do

  context 'tests with prerequisite' do
    base_dir = '/tmp'
    list_of_dirs = %w|dir1 dir2|
    # NOTE: To be able run Puppet in clean ruby-less uru enviroment,
    # needed to install running one time from within uru:
    # uru gem install nokogiri

    # NOTE:
    # before(:all)
    # before(:each)
    # - none work when outside of scopes
    # left as-is and make the directories manually (too subtle to be time woorthy
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
        RUBY='ruby'
        if [ ! -z  $URU_INVOKER ]
        then
          RUBY='/uru/uru_rt ruby'
        fi
        ruby -e '#{ruby_script}'
      EOF
      )
    end

    context 'using verbatim paths' do
      target_dir = "#{base_dir}/#{list_of_dirs[0]}"
      puppet_manifest = <<-EOF
        exec {'command with condition':
          command   => 'echo Done',
          provider  => shell,
          logoutput => true,
          onlyif    => 'test -e "#{target_dir}" && ! test -L "#{target_dir}"',
        }
      EOF
      describe command( <<-EOF
        puppet apply -e "#{puppet_manifest.gsub(/\n/, '').gsub(/\s+/, ' ')}"
        find #{base_dir} -maxdepth 1 -type d
      EOF
    ) do
        its(:stderr) { should be_empty }
        # to make rspec display the actual output, add the expectation which will not be met
        its(:stdout) { should include 'Done' }
        its(:stdout) { should include 'Exec[command with condition]/returns: Done' }
        its(:exit_status) {should eq 0 }
      end
    end
    context 'using shell variables in puppet exec command' do

      target_dir = "#{base_dir}/#{list_of_dirs[0]}"
      puppet_manifest = <<-EOF
        \\$target_dir = '#{target_dir}'; exec {\\"command with condition for \\${target_dir}\\":
          command   => 'echo Done',
          provider  => shell,
          logoutput => true,
          onlyif    => \\"TARGET_DIR=\\${target_dir};test -e \\\\\\${TARGET_DIR} && ! test -L \\\\\\${TARGET_DIR}\\",
        }
      EOF
      describe command( <<-EOF
        puppet apply -e "#{puppet_manifest.gsub(/\n/, '').gsub(/\s+/, ' ')}"
      EOF
    ) do
        its(:stderr) { should be_empty }
        its(:stdout) { should include 'Done' }
        its(:stderr) { should_not include 'Could not parse for environment production' }
        its(:stdout) { should match /Exec\[command with condition for .*\]\/returns: Done/ }
        its(:exit_status) {should eq 0 }
      end
    end
    context 'not specifying the provider attribute to the custom type' do
      # NOTE: frequently overlooked
      target_dir = "#{base_dir}/#{list_of_dirs[0]}"
      puppet_manifest = <<-EOF
        \\$target_dir = '#{target_dir}'; exec {\\"command with condition for \\${target_dir}\\":
          command  => 'echo Done',
          logoutput => true,
          onlyif   => \\"TARGET_DIR=\\${target_dir};test -e \\\\\\${TARGET_DIR} && ! test -L \\\\\\${TARGET_DIR}\\",
        }
      EOF
      describe command( <<-EOF
        puppet apply -e "#{puppet_manifest.gsub(/\n/, '').gsub(/\s+/, ' ')}"
      EOF
      ) do
        [
          'Parameter onlyif failed',
          'Please qualify the command or specify a path',
        ].each do |line|
          its(:stderr) { should include line }
        end
        its(:exit_status) { should_not eq 0 }
      end
    end
    context 'test 4' do

      target_dir = "#{base_dir}/#{list_of_dirs[0]}"
      puppet_manifest = <<-EOF
        exec {'command with condition':
          command   => 'echo Done',
          provider  => shell,
          logoutput => true,
          onlyif    => 'test -e "#{target_dir}" && ! test -L "#{target_dir}"',
        }
      EOF
      describe command( <<-EOF
        puppet apply -e "#{puppet_manifest.gsub(/\n/, '').gsub(/\s+/, ' ')}"
        find #{base_dir} -maxdepth 1 -type d
      EOF
    ) do
        its(:stderr) { should be_empty }
        # to make rspec show the actual output, make the expectation unrealistic
        its(:stdout) { should include 'Done' }
        its(:stdout) { should include 'Exec[command with condition]/returns: Done' }
        its(:exit_status) {should eq 0 }
      end
    end
  end
  context 'tests with user local library' do
    # not uncommon with ops to rely on Python
    lib_dir = "#{ENV.fetch('HOME')}/.local/lib/python2.7/site-packages"
    # the contents are diverse:
    # MySQLdb
    # _mysql_exceptions.py
    # _mysql_exceptions.pyc
    # _mysql_exceptions.pyo
    # MySQL_python-1.2.5-py2.7.egg-info
    # _mysql.so
    # PyYAML-5.3.1-py2.7.egg-info
    # yaml

    context 'dummy' do
    
      puppet_manifest = <<-EOF
        \\$lib_dir = '#{lib_dir}'; exec {\\"command with dependencies in \\${lib_dir}\\":
          command   => 'echo Done',
          provider  => shell,
          logoutput => true,
          onlyif    => \\"LIB_DIR=\\${lib_dir}; test -d \\\\\\${LIB_DIR}\\",
        }
      EOF
      describe command( <<-EOF
        puppet apply -e "#{puppet_manifest.gsub(/\n/, '').gsub(/\s+/, ' ')}"
      EOF
    ) do
        # in real scenario likely be some volatile facts one can not mock
        its(:stderr) { should include 'Facter: error' }
        its(:stdout) { should include 'Done' }
        its(:stderr) { should_not include 'Could not parse for environment production' }
        its(:stdout) { should match /Exec\[command with dependencies in .*\]\/returns: Done/ }
        its(:exit_status) {should eq 0 }
      end
    end
    context 'real', :if => ENV.has_key?('COMMAND') do

      command = ENV.fetch('COMMAND', 'echo COMMAND not defined')
      puppet_manifest = <<-EOF
        \\$lib_dir = '#{lib_dir}'; exec {\\"command with dependencies in \\${lib_dir}\\":
          command   => '#{command}',
          provider  => shell,
          logoutput => true,
          onlyif    => \\"LIB_DIR=\\${lib_dir}; test -d \\\\\\${LIB_DIR}\\",
        }
      EOF
      describe command( <<-EOF
        puppet apply -e "#{puppet_manifest.gsub(/\n/, '').gsub(/\s+/, ' ')}"
      EOF
    ) do
        its(:stderr) { should be_empty }
        its(:stdout) { should be_empty }
        its(:exit_status) {should eq 0 }
      end
    end

  end
