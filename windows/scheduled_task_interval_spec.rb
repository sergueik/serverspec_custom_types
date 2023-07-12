require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine

# based on: http://www.cyberforum.ru/powershell/thread2516509.html
context 'Scheduled Task Intervals' do
  describe command(<<-EOF
    function intervalToTimeSpan {
      param(
        [String] $interval
      )
      if ($interval -match 'P(\\d+)(\\w)'){
        $TimeSpan = switch ($Matches[2])
        {
          'D' {New-TimeSpan -Days $Matches[1]}
        }
      } elseif ($interval -match 'PT(\\d+)(\\w)'){
        $TimeSpan = switch ($Matches[2])
        {
          'D' {New-TimeSpan -Days $Matches[1]}
          'H' {New-TimeSpan -Hours $Matches[1]}
          'M' {New-TimeSpan -Minutes $Matches[1]}
          'S' {New-TimeSpan -Seconds $Matches[1]}
        }
      }
      $TimeSpan
    }
    # Get-ScheduledTask needs to be installed exicitly
    # with Powershell PSVersion 4.0
    # The term 'Get-ScheduledTask' is not recognized as the name of a cmdlet, function, script file, or operable program.
    # https://stackoverflow.com/questions/51147611/get-scheduledtask-command-does-not-work-in-windows-server-2008-r2/51147933
    $o = Get-ScheduledTask |
    where-object {$_.Triggers.Repetition.interval -ne $null } |
    select-object -first 1 | select-object -expandproperty Triggers |
    select-object -expandproperty Repetition;
    $interval = intervalToTimeSpan -interval ($o.interval)
    write-output $interval | format-list
    # Days
    # Hours
    # Milliseconds
    # Minutes
    # Seconds
    # Ticks
    # TotalDays
    # TotalHours
    # TotalMilliseconds
    # TotalMinutes
    # TotalSeconds

  EOF
  ) do
    its(:exit_status) { should eq 0 }
    [
#      'Days',
#      'Hours',
#      'Minutes',
#      'Seconds',
      'Milliseconds',
      'Ticks',
#      'TotalDays',
#      'TotalHours',
#      'TotalMinutes',
#      'TotalSeconds',
#      'TotalMilliseconds'
    ].each do |unit|
      its(:stdout) { should match Regexp.new("#{unit}\\s+:\\s+\\d+") }
    end
  end
  describe command(<<-EOF
    function intervalToTimeSpan {
      param(
        [String] $interval
      )
      if ($interval -match 'PT(\\d+)(\\w)'){
        $TimeSpan = switch ($Matches[2])
        {
          'D' {New-TimeSpan -Days $Matches[1]}
          'H' {New-TimeSpan -Hours $Matches[1]}
          'M' {New-TimeSpan -Minutes $Matches[1]}
          'S' {New-TimeSpan -Seconds $Matches[1]}
        }
      }
      $TimeSpan
    }
    $task_name = '\\Microsoft\\Windows\\CertificateServicesClient\\UserTask'
    $command_output  = @(& 'schtasks.exe' '--%' '/query /tn ' $task_name '/xml') -join ''
    # $command_output
    [System.XML.XMLDocument]$o = new-object -typeName 'System.XML.XMLDocument'
    if ($command_output -ne $null) {
      write-output ('Loading XML {0}...' -f $command_output.Substring(0,20 ) )
      $o.LoadXML($command_output)
      $text = $o.'Task'.'Triggers'.'LogonTrigger'.'Repetition'.'Interval'
      write-output ('Converting text {0}...' -f $text )
      $interval = intervalToTimeSpan -interval $text
      write-output $interval | format-list
    } else {
      write-error ('Cannot load task {0}' -f $task_name )
    }
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    %w|
      Days
      Hours
      Minutes
      Seconds
      Milliseconds
      Ticks
      TotalDays
      TotalHours
      TotalMinutes
      TotalSeconds
      TotalMilliseconds
    |.each do |unit|
      its(:stdout) { should match Regexp.new("#{unit}\\s+:\\s+\\d+") }
    end
    its(:exit_status) { should eq 0 }
    its(:stderr) { should be_empty }
  end
end
