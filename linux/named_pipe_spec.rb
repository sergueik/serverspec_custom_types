# require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Pipes' do
  process = '/var/itlm/tlmagent.bin'
  named_pipe = '/var/itlm/clisock'
  process_mask = '[t]lmagent.bin'

  describe command("/bin/netstat -ano | grep '#{named_pipe}'") do
    [ 'STREAM', 'LISTENING', named_pipe].each do |word|
      its (:stdout) do
        should contain word
      end
    end
    %w|STREAM LISTENING named_pipe|.each do |word|
      its (:stdout) { shoult contain word }
    end	
  end

  describe command("/bin/netstat -anp | grep $(ps ax | grep '#{process_mask}' | awk '{print $1}')") do
    [ 'STREAM', 'LISTENING', named_pipe].each do |word|
      its (:stdout) do
        should contain word
      end
    end
  end
  describe file(named_pipe)  do
    it { should be_socket }
  end
end
