require "fileutils"

module Ftpspec
  class Setup
    def self.run

      file_contents = <<-EOF
require "spec_helper"

describe "/httpdocs/index.html" do
  it { should be_mode "644" }
end
      EOF

      rakefile_contents = <<-EOF
require "rake"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "spec/*/*_spec.rb"
end

task :default => :spec
      EOF

      spec_helper_contents = <<-EOF
require "ftpspec"
require "rubygems"
require "rspec"
require "net/ftp"

RSpec.configure do |c|
  c.add_setting :ftp, :default => nil
  c.before do
    hostname = ""
    user = ""
    password = ""
    c.ftp = Net::FTP.new
    c.ftp.passive = true
    c.ftp.connect(hostname)
    c.ftp.login(user, password)
    Ftpspec.set_ftp
  end
  c.after do
    c.ftp.close
  end
end
      EOF

      FileUtils.mkdir "spec"
      File.open("spec/ftp_spec.rb", "w") do |f|
        f.puts file_contents
      end
      File.open("spec/spec_helper.rb", "w") do |f|
        f.puts spec_helper_contents
      end
      File.open("Rakefile", "w") do |f|
        f.puts rakefile_contents
      end
    end
  end
end
