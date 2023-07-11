if File.exists?( 'spec/windows_spec_helper.rb')
# Copyright (c) Serguei Kouzmine
  require_relative '../windows_spec_helper'
end

#
# based on https://ss64.com/nt/cd.html
context 'Undocumented environment variables' do
  describe command( <<-EOF
  cmd %%- /c echo %=C:%
  EOF
  ) do
  end
end