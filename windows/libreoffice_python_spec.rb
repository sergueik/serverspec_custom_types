require_relative '../windows_spec_helper'


context 'LibreOffice python' do
  # see also: https://github.com/unoconv/unoconv
  #
  office_verison = '7'
  embedded_python_versions =
  {
    '6' => '3.5.5'
    '7' => '3.7.7'
  }
  python_version = embedded_python_versions[office_version]
  libreoffice_home = 'c:\Program Files\LibreOffice'
  [
    "#{libreoffice_home}\\program\\python3.dll",
    "#{libreoffice_home}\\program\\python-core-#{python_version}\\bin\\python.exe",
    "#{libreoffice_home}\\program\\python.exe"
  ].each do |filepath|
    describe file filepath do
      it { should be_file }
    end
  end
  custom_path = "#{libreoffice_home}\\programi";"#{libreoffice_home}\\program\\python-core-#{python_version}\\bin"
  describe command 'python -V' do
    let(:path) { custom_path }
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain "Python #{python_version}\\n" }
  end
  # Failing example
  # NOTE the back slashes
  program = 'print(\\"test\\")'
  describe command "python -c \"#{program}\"" do
    let(:path) { custom_path }
    its(:exit_status) { should eq 256 }
    its(:stderr) { should contain 'SyntaxError: unexpected EOF while parsing' }
  end
  program = "print(\"\"test\"\")"
  [
    "python -c \"#{program}\"",
    "cmd --% /c python -c \"#{program}\""
  ].each do |command|
    describe command  do
      let(:path) { custom_path }
      its(:exit_status) { should eq 256 }
      its(:stderr) { should contain "NameError: name 'test' is not defined" }
    end
  end
  program = "print('test')"
  describe command "python -c \"#{program}\"" do
    let(:path) { custom_path }
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'test' }
  end
  program = "print(\\\"\"test\\\"\")"
  describe command "cmd -- % /c python -c \"#{program}\"" do
    let(:path) { custom_path }
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'test' }
  end
  # python -c "help(\"modules\")"
  # path=%path%;c:\Program Files\LibreOffice\program;c:\Program Files\LibreOffice\program\python-core-3.5.5\bin
  # python -c "help(""modules"")"
  # $env:path = "${env:path};c:\Program Files\LibreOffice\program;c:\Program Files\LibreOffice\program\python-core-3.5.5\bin"

end


