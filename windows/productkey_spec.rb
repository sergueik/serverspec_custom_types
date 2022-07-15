require_relative '../windows_spec_helper'

# NOTE: will only work on Windows 8.1, Windows 10 and later - will fail on Windows 7
# see also: https://qna.habr.com/q/1177088
#

context 'Original Product Key' do
  key = 'OA3xOriginalProductKey'
  
  describe command(<<-EOF
    wmic.exe path softwarelicensingservice get #{key}
  EOF
  ) do

    its(:stderr) do
      should_not contain 'Invalid query'
    end
    its(:stdout) do
      should contain key
    end
    # the following will fail on bootleg and / or evaluation images 
    its(:stdout) do
      should match /[0-9A-Z]{5,5}-[0-9A-Z]{5,5}-[0-9A-Z]{5,5}-[0-9A-Z]{5,5}-[0-9A-Z]{5,5}/
    end
  end
  describe command(<<-EOF
    (Get-WmiObject -query 'select * from SoftwareLicensingService').#{key}
  EOF
  ) do
    its(:stdout) do
      should match /[0-9A-Z]{5,5}-[0-9A-Z]{5,5}-[0-9A-Z]{5,5}-[0-9A-Z]{5,5}-[0-9A-Z]{5,5}/
    end
  end
end
