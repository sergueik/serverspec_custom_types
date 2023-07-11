if File.exists?( 'spec/windows_spec_helper.rb')
# Copyright (c) Serguei Kouzmine
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

# http://postgresguide.com/utilities/psql.html
context 'Pgsql' do
  # NOTE: setup not fully described
  context 'Configuration' do
    describe file('/var/lib/pgsql/data/pg_hba.conf') do
      its(:content) { should match Regexp.new '^\s*host\s+all\s+all\s+127.0.0.1/32\s+trust' }
      its(:content) { should_not match Regexp.new '^\s*host\s+all\s+all\s+127.0.0.1/32\s+ident' }
    end
  end
  postgres_version = '9.2.24'
  tmp_path = '/tmp'
  username = 'postgres'
  database = 'template1'
  sample_query = 'SELECT VERSION()'

  context 'Inline Query with pgsql' do
    describe command(<<-EOF
      systemctl status -l postgresql
      # NOTE: user context switch is to exercise postgresql ident authentication
      su #{username} -c "psql -c '#{sample_query}'"
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should contain "PostgreSQL #{postgres_version} on" }
    end
  end
  context 'Read psql query from the file' do

    sample_query_file = "#{tmp_path}/query.txt"

    # NOTE: The \g is reported as an error - no need in \g at the end of SQL statement when from file.
    sample_query_data = <<-EOF
      #{sample_query}
    EOF
    before(:each) do
      $stderr.puts "Writing #{sample_query_file}"
      file = File.open(sample_query_file, 'w')
      file.puts sample_query_data
      file.close
    end
    describe command(<<-EOF
      systemctl status -l postgresql
      1>/dev/null 2>/dev/null pushd '#{tmp_path}'
      # NOTE: user context switch is to exercise postgresql ident authentication
      su #{username} -c "psql -f '#{sample_query_file}'"
      1>/dev/null 2>/dev/null popd
    EOF

    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should contain "PostgreSQL #{postgres_version} on" }
    end
  end
end
