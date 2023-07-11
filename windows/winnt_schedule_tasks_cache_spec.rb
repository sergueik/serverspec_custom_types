require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Registry' do
  task = '{8A2CE4D0-352E-43FE-8FB1-05140580EA96}'
  describe windows_registry_key("HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Schedule\\TaskCache\\Tasks\\#{task}") do
    it do
      should respond_to(:exists?)
      should exist
      should respond_to(:has_property?).with(2).arguments
      should respond_to(:has_property?).with(1).arguments
      should have_property('Path', :type_string)
      should respond_to(:has_value?).with(1).arguments
      should have_property_value( 'URI', :type_string_converted, '\automation\example_task_app' )
    end
  end

  context 'Properties' do
    key = 'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows NT/CurrentVersion/Schedule/TaskCache/Tasks/' + task
    names = %w|
      Path
      Hash
      Schema
      Description
      URI
      Triggers
      Actions
      DynamicInfo
      Author
    |

    describe ("Registry Property Name #{name}") do
      describe command("get-item -path 'Registry::#{ key.gsub('/', '\\\\') }' | select-object -expandproperty Property ") do
        names.each do |name|
          its(:stdout) { should match /(\A|\R)#{name}(\R|\Z)/}
        end
      end
    end

    task_path = 'automation/example_task_app'
    key = 'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows NT/CurrentVersion/Schedule/TaskCache/Tree/' + task_path
    names = %w|
      SD
      Id
      Index
    |
    describe ("Registry Property Name #{name}") do
      describe command("get-item -path '#{ key.gsub('/', '\\\\').gsub('HKEY_LOCAL_MACHINE','HKLM:') }' | select-object -expandproperty Property ") do
        names.each do |name|
          its(:stdout) { should match /(\A|\R)#{name}(\R|\Z)/}
        end
      end
    end
    key = 'HKLM:/SOFTWARE/Microsoft/Windows NT/CurrentVersion/Schedule/TaskCache/Tree/' + task_path
    describe ("Registry Property Name #{name}") do
      describe command("get-item -path '#{ key.gsub('/', '\\\\').gsub('HKEY_LOCAL_MACHINE','HKLM:') }' | select-object -expandproperty Property ") do
        names.each do |name|
          its(:stdout) { should match /(\A|\R)#{name}(\R|\Z)/}
        end
      end
    end

    name = 'Id'
    valueType = 'ExpandString'
    value = task

    describe ("Registry Value of #{name}") do
      describe command("(Get-Item '#{ key.gsub('/', '\\\\') }').GetValue('#{name}') -replace \"\\n\", '' -replace '\\\\', '/' " ) do
        its(:stdout) { should match Regexp.new(value.gsub('\\', '/'), Regexp::IGNORECASE) }
        its(:stdout) { should match /#{value.gsub('\\', '/')}/i}
        its(:stdout) { should contain value}
      end
    end
  end
end
