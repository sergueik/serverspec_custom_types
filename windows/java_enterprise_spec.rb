require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Java launchers', :if => os[:family] == 'windows' do
# this will only pass in enterprise environment with complex policies

  [
      'java.exe',
      'javax.exe',
      'javaw.exe',
      'jshell.exe'
  ].each do |filename|
		basedir = 'c:/Program Files/Common Files/Oracle/Java/javapath'
		# NOTE: the above path is a JUNCTON, like soft link, it is traversable
		describe file( "#{basedir}/#{filename}"), :if => false do
			its(:size) { should be 665336 } 
			# same for every one of these files
		end
		describe command(<<-EOF
			$filename = '#{filename}'
			$path = where.exe $filename | select-object -first 1
			dir $path -force | select-object -property versioninfo | format-list
			# NOTE: convertFrom-String will fail to parse this
		EOF
		) do
			{
				'OriginalFilename' => 'Shim Console Laucher',
				'InternalName' => 'shimconsole.exe'
			}.each do |key,value|
				its(:stdout) { should match match(Regexp.new( "#{key} * : *" + Regexp.escape(value), Regexp::IGNORECASE)) }
			end
			its(:exit_status) { should eq 0 }
		end
	end
end

