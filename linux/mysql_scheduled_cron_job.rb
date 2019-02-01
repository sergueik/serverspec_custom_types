require 'spec_helper'

# The below represents a set of expecttions on mysql scheduled command
# which is typically provisioned into the node by Puppet, Chef and the like in a
# set of cron job (calling the), shell script (calling the), sql script that is loading a collection of parameters from hiera to a boilerplate SQL statement and executes the latter
context 'MySQL scheduled command' do
  context 'Cron job' do
    cronjob_user = 'root'
    shell_script = '/opt/jobs/script.sh'
    cron_schedule_expression = '*/5 * * * *'
    describe cron do
      it { should have_entry("#{cron_stchedule_expression} #{shell_script}").with_user(cronjob_user) }
    end
  end
  context 'Shell script' do
    shell_script = '/opt/jobs/script.sh'
    sql_script = '/opt/jobs/script.sql'
    line = "QUERY=$(cat '#{sql_script}')"
    describe file(shell_script) do
      its(:content) { should match Regexp.escape(line) }
    end
  end
  context 'SQL script' do
    variable_name = 'number_of_days'
    variable_value = 7
    line = "@#{viriable_name} = #{variable_value}"
    describe file(sql_script) do
      its(:content) { should match Regexp.escape(line) }
    end
  end
end
