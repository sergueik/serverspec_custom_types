require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Escaping backticks and special varialbles' do
  describe command ("upower -i $(upower -e | grep -i battery | head -1)| grep -e '[ a-z-]*: *[^ ][^ ]*.*$'") do
    its(:exit_status) { should be 0 }
    its(:stderr) { should be_empty }
    {
      'power supply' => 'yes',
      'has history' => 'yes',
      'has statistics' => 'yes',
      'present' => 'yes',
      'rechargeable' => 'yes',
      'state' => '(dis)?charging',
      'warning-level' => 'none',
      'energy' => '[0-9.]+ Wh',
      'energy-empty' => '0 Wh',
      'energy-full' => '[0-9.]+ Wh',
      'energy-full-design' => '[0-9.]+ Wh',
      'energy-rate' => '[0-9.]+ W',
      'voltage' => '[0-9.]+ V',
      # TODO: the upower information contains either 'time to empty' or 'time to full' but not both at the same time
      # 'time to empty' => '[0-9.]+ hours',
      # 'time to full' => '[0-9.]+ hours',
      '(time to empty|time to full)' => '([0-9.]+ hours|[0-9.]+ minutes)',
      'percentage' => '[0-9]+%',
      'capacity' => '[0-9.]+%',
    }.each do |key,val|
      its(:stdout) { should match Regexp.new("#{key}: *#{val}", Regexp::IGNORECASE ) }
    end
  end
end
