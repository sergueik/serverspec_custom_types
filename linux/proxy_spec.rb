require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'pp'
context 'Jenkins' do

  context 'Port Forwarding' do
    [
      8443,
      9443
    ].each do |https_port|
      context "port #{https_port}" do
        describe host('localhost') do
          it { should be_reachable.with(:port => https_port )}
        end
      end
    end
    [
      8080,
    ].each do |http_port|
      context "port #{http_port}" do
        describe host('localhost') do
          it { should_not be_reachable.with(:port => http_port )}
        end
      end
    end
  end  
end