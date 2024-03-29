require 'spec_helper'
# Copyright (c) Serguei Kouzmine

$DEBUG = true
$CLEAN = (ENV.fetch('CLEAN', false) =~ (/^(true|t|yes|y|1)$/i))
$AGE = ENV.fetch('AGE', 10).to_i # WARNING - long ages slows down the test run

context 'Jenkins Command' do

  parentdir = '/tmp'
  datafile = '/tmp/removal.json'
  age_diff = $AGE
  logfile = '/tmp/runner.log'
  if $CLEAN
    before(:all) do
      Specinfra::Runner::run_command( <<-EOF
        LOGFILE='#{logfile}'
        AGE=#{age_diff}
        cat /dev/null > $LOGFILE
        pushd '#{parentdir}' > /dev/null
        # initialize directories
        for CNT in  $(seq 1 10)
        do
          D="dir_${CNT}"
          if [ ! -d $D ]
          then
            echo "Initialize \\"${D}\\"" | tee -a $LOGFILE
            mkdir $D
          fi
        done
        # age directories
        for CNT in $(seq 1 10)
        do
          D="dir_${CNT}"
          echo "Touch \\"${D}\\"" | tee -a $LOGFILE
          touch $D
          echo "Sleep ${AGE} seconds." | tee -a $LOGFILE
          sleep $AGE
        done
        1>&2 ls -ltrd dir_*
        popd > /dev/null
      EOF
      )
    end
  end
  context 'Listing' do
    describe command(<<-EOF
      pushd '#{parentdir}' > /dev/null
      ls -1dtr dir_* | tr '\\n' ' '
      popd > /dev/null
    EOF
    ) do
      its(:stdout) { should match Regexp.new('dir_1 dir_2 dir_3 dir_4 dir_5 dir_6 dir_7 dir_8 dir_9 dir_10') }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end
  context 'Step 1' do
    test_dirname='dir_6'
    describe command(<<-EOF
      USER='root'
      MARKER='#{test_dirname}'
      pushd '#{parentdir}' > /dev/null
      LIST=$(find . -maxdepth 1 -type d -and -name 'dir_*' -and -user $USER -and \\( ! -cnewer $MARKER \\))
      echo $LIST
      popd > /dev/null
    EOF
    ) do
     # random order
      %w|dir_5 dir_3 dir_2 dir_4 dir_6 dir_1|.each do |dir|
        its(:stdout) { should match Regexp.new("#{dir}") }
      end
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end
  context 'Step 2' do
    keep_dirname='dir_6'
    describe command(<<-EOF
      # repeat step 1
      USER='root'
      MARKER='#{keep_dirname}'
      pushd '#{parentdir}' > /dev/null
      LIST=$(find . -maxdepth 1 -type d -and -name 'dir_*' -and -user $USER -and \\( ! -cnewer $MARKER \\))
      # step 2
      CNT=0
      KEEP_COUNT=3
      for D in $(ls -1dt $LIST); do
        CNT=$(expr $CNT + 1 )
        if [[ $CNT -gt $KEEP_COUNT ]]; then
          echo "Purge $D"
        else
          echo "Keep $D"
        fi
      done
      popd > /dev/null
    EOF
    ) do
     # older removed
      %w|dir_1 dir_2 dir_3|.each do |dir|
        its(:stdout) { should match Regexp.new("Purge ./#{dir}") }
      end
      # '#{keep_dirname}' and ($KEEP_COUNT -1) old dirs and all newer then '#{keep_dirname}' kept
      %w|dir_4 dir_5 dir_6|.each do |dir|
        its(:stdout) { should match Regexp.new("Keep ./#{dir}") }
      end
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end
  context 'Step 2, Array version' do
    keep_dirname='dir_6'
    describe command(<<-EOF
      # repeat step 1
      USER='root'
      MARKER='#{keep_dirname}'
      pushd '#{parentdir}' > /dev/null
      LIST=$(find . -maxdepth 1 -type d -and -name 'dir_*' -and -user $USER -and \\( ! -cnewer $MARKER \\))
      # step 2
      CNT=0
      KEEP_COUNT=3
      ARRAY=()
      for D in $(ls -1dt $LIST); do
        CNT=$(( $CNT + 1 ))
        if [[ $CNT -gt $KEEP_COUNT ]]; then
          ARRAY+=($D)
        fi
      done
      echo "Remove: ${ARRAY[*]}"
      for CNT in $(seq 0 ${#ARRAY[@]})
      # one extra
      do
        echo "ARRAY[${CNT}] = ${ARRAY[$CNT]}"
      done
      popd > /dev/null
    EOF
    ) do
      its(:stdout) { should match Regexp.new 'Remove: ./dir_3 ./dir_2 ./dir_1' }
      its(:stdout) { should match Regexp.new 'ARRAY[0] = ./dir_3' }
      # ARRAY[1] = ./dir_2
      # ARRAY[2] = ./dir_1
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end
end
