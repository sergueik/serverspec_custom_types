require 'spec_helper'

# Illustration of decorating the rspec with environment checks in various ways

$DEBUG = false

# omitted a whole can of worms of hand mande to_boolean in Ruby
# see https://stackoverflow.com/questions/36228873/ruby-how-to-convert-a-string-to-boolean

$CORRECTLY_DEFINED_DEBUG = ENV.fetch('CORRECTLY_DEFINED_DEBUG', false)
$stderr.puts "Literal $CORRECTLY_DEFINED_DEBUG='#{$CORRECTLY_DEFINED_DEBUG}'"
$stderr.puts "Evaluated $CORRECTLY_DEFINED_DEBUG='#{$CORRECTLY_DEFINED_DEBUG ? 'true': 'false'}'"

# easily overlooked error in quoting the default value of $DEBUG
$DEBUG = ENV.fetch('DEBUG', 'false')
$stderr.puts "Literal $DEBUG='#{$DEBUG}'"
$DEBUG = (ENV.fetch('DEBUG', 'false') =~ /^(true|t|yes|y|1)$/i)
$stderr.puts "Evaluated $DEBUG='#{$DEBUG ? 'true': 'false'}'";

class String
  def to_boolean
    self =~ /^(true|t|yes|y|1)$/i
  end
end

class NilClass
  def to_boolean
    false
  end
end

class TrueClass
  def to_boolean
    true
  end

  def to_i
    1
  end
end

class FalseClass
  def to_boolean
    false
  end

  def to_i
    0
  end
end

class Integer
  def to_boolean
    to_s.to_boolean
  end
end


# Illustration of decorating the rspec with environment checks in various ways
# to suppress the tests, unset SPECIFIC_ENVIRONMENT
# to engage the tests, export SPECIFIC_ENVIRONMENT=somevalue
# NOTE:the value is not properly tested atm

context 'Tests limited to a Specific Environment' do

  $specific_environment = ENV.fetch('SPECIFIC_ENVIRONMENT', nil)
  if $DEBUG
    $stderr.puts "DEBUG: $specific_environment = '#{$specific_environment}'"
  end
  if $DEBUG
    $stderr.puts "DEBUG: $specific_environment = '#{$specific_environment.to_boolean}'"
  end
  unless $specific_environment.nil?
    context 'sensitive context 1' do
      $stderr.puts "Running #{self.to_s} under specific environment ($specific_environment = '#{$specific_environment}')"
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
    context 'sensitive context 2' do
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
