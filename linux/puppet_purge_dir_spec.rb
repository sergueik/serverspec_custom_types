require 'spec_helper'

context 'Examine result of Puppet Apply run' do

  context 'Summary' do
    list_of_dirs = [
      '2.4.1',
      '2.4.2',
      '2.4.3',
      '2.4.4',
      '2.4.5',
      'logs',
    ]
    last_version = '2.4.5'
    base_dir = '/opt/apache'

    before(:each) do

      ruby_script = <<-EOF
        require "fileutils"
        
        dirs = #{list_of_dirs}
        base_dir = "#{base_dir}"
        dirs.each do |dirname|
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

    puppet_manifest = <<-EOF
      file {'#{base_dir}':
        ensure       => directory',
        recurselimit => 1,
        recurse      => true,
        purge => true,
        force => true,
        ignore => ['current','#{last_version}']
      }
    EOF
    # TO run Puppet in ruby-less uru enviroment, needed to
    # uru gem install nokogiri
    describe command("puppet apply -e \"#{puppet_manifest.gsub(/\n/, '').gsub(/\s+/, ' ')}\"") do
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end
end

