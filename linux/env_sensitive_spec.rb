require 'spec_helper'

# Illustration of decorating the rspec with environment checks in various ways
# to suppress the tests, unset SPECIFIC_ENVIRONMENT
# to engage the tests, export SPECIFIC_ENVIRONMENT=somevalue
# NOTE:the value is not properly tested atm


$DEBUG = false

context 'Tests limited to a Specific Environment' do

  $specific_environment = ENV.fetch('SPECIFIC_ENVIRONMENT', nil)
  if $DEBUG
    $stderr.puts "DEBUG: $specific_environment = '#{$specific_environment}'"
  end
  unless $specific_environment.nil?
    context 'test1' do
      $stderr.puts "Running #{self.to_s} under specific environment"
      describe file('/var') do
        it { should_not be_file }
      end
    end
  else  
    $stderr.puts "Skipped test ($specific_environment = '#{$specific_environment}')"
  end
  $specific_environment = ENV.has_key?('SPECIFIC_ENVIRONMENT')
  if $DEBUG
    $stderr.puts "DEBUG: $specific_environment = '#{$specific_environment}'"
  end
  if $specific_environment
    context 'test2' do
      $stderr.puts "Running #{self.to_s} under specific environment ($specific_environment = '#{$specific_environment}')"
      describe file('/var') do
        it { should be_directory }
      end
    end
  else  
    $stderr.puts "Skipped test ($specific_environment = '#{$specific_environment}')"
  end
  context 'test3', :if => ENV.has_key?('SPECIFIC_ENVIRONMENT') do
    # NOTE: the note will be printed regrdless of the SPECIFIC_ENVIRONMENT key evaluation
    $stderr.puts "Running #{self.to_s} in the presence of specific environment"	
    describe file('/var') do
      it { should be_directory }
    end
  end
end
