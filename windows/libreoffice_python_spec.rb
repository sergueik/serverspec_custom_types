require_relative '../windows_spec_helper'


context 'LibreOffice python' do
  # see also: https://github.com/unoconv/unoconv
  python_version = '3.5.5'
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
  describe command 'python -V' do
    let(:path) { "#{libreoffice_home}\\program;#{libreoffice_home}\\program\\python-core-#{python_version}\\bin" }
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain "Python #{python_version}\\n" }
  end
  # Failing example
  # NOTE the back slashes
  program = 'print(\\"test\\")'
  describe command "python -c \"#{program}\"" do
    let(:path) { "#{libreoffice_home}\\program;#{libreoffice_home}\\program\\python-core-#{python_version}\\bin" }
    its(:exit_status) { should eq 256 }
    its(:stderr) { should contain 'SyntaxError: unexpected EOF while parsing' }
  end
  program = "print('test')"
  describe command "python -c \"#{program}\"" do
    let(:path) { "#{libreoffice_home}\\program;#{libreoffice_home}\\program\\python-core-#{python_version}\\bin" }
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'test' }
  end
  program = "print(\"\"test\"\")"
  describe command "python -c \"#{program}\"" do
    let(:path) { "#{libreoffice_home}\\program;#{libreoffice_home}\\program\\python-core-#{python_version}\\bin" }
    its(:exit_status) { should eq 256 }
    its(:stderr) { should contain "NameError: name 'test' is not defined" }
    
  end
  # python -c "help(\"modules\")"
  # it wasn't my fault
end

