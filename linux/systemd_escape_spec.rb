require 'spec_helper'
require 'fileutils'

# https://www.freedesktop.org/software/systemd/man/systemd-escape.html
context 'Escaping backticks and special varialbles' do
  [
    '`date +%F`', # this one survives
    '`date +%Y%m%d_%H%M%S`' # this one gets filled to unrecognizable way by systemd's own special var interpolation
  ].each do |date_suffix|
    describe command ("systemd-escape '#{date_suffix}'") do
      its(:exit_status) { should be 0 }
      its(:stdout) { should match /\\x[0-9a-d]+/i }
      its(:stderr) { should be_empty }
    end
    # TODO: exercise systemctl --no-page -o cat show to contain readable stuff
  end
end