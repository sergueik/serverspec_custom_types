require 'spec_helper'

context 'set user id attributes' do

  filename = '/file'
  dir = '/tmp'
  filepath = "#{dir}/#{filename}"
  
  before(:each) do
    Specinfra::Runner::run_command( <<-EOF
      touch '#{filepath}'
      chmod +s  '#{filepath}'
      chmod 4775 '#{filepath}'
    EOF
    )
  end
  [
  "stat -c '%A' '#{filepath}' | grep -qv '\\-..s.'",
  "stat -c '%a' '#{filepath}' | grep -qv '^4'",
  # find #{dir} -maxdepth 1 -name '#{filename}' -perm 4775
  ].each do |commandline|
    describe command(<<-EOF
      #{commandline}
    EOF
    ) do
      its(:exit_status) { should eq 1 }
    end
  end
end
