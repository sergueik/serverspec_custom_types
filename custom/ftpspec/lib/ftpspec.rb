require "rubygems"
require "rspec"
require "ftpspec/version"
require "ftpspec/setup"
require "ftpspec/matchers"
require "ftpspec/commands"
require "ftpspec/utils"

module Ftpspec
  @@ftp = nil
  def self.set_ftp
    @@ftp = RSpec.configuration.ftp
  end
  def self.get_ftp
    @@ftp
  end
end
