RSpec::Matchers.define :be_mode do |expected|
  match do |target|
    Ftpspec::Commands.check_mode(target, expected)
  end
end

RSpec::Matchers.define :be_file do
  match do |target|
    Ftpspec::Commands.check_file(target)
  end
end

RSpec::Matchers.define :be_directory do
  match do |target|
    Ftpspec::Commands.check_directory(target)
  end
end

RSpec::Matchers.define :be_owned_by do |expected|
  match do |target|
    Ftpspec::Commands.check_owner(target, expected)
  end
end

RSpec::Matchers.define :be_grouped_into do
  match do |target|
    Ftpspec::Commands.check_group(target, expected)
  end
end
