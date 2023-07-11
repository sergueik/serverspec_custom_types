
# Copyright (c) Serguei Kouzmine
require_relative '../windows_spec_helper'

context 'Determine which .NET Framework versions are installed (specific to .NET Framework)' do
  # based on https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
  # see also: https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/versions-and-dependencies
  context 'Cmdlet' do
    versions = %w|
      4.8
      4.7.2
      4.7.1
      4.7
      4.6.2
      4.6.1
      4.6
      4.5.2
      4.5.1
      4.5
    |
    # NOTE: acidentally can construct a bad regexp:
    # versions_re = '(?' + ...
    # undefined group option:
    # undefined group option: /^(?4\.8|4\.7\.2|4\.7\.1|4\.7|4\.6\.2|4\.6\.1|4\.5\.2|4\.5\.1)$/
    versions_re = '(' + versions.map { |x| x.gsub(/\./, '\.')}.join('|') + ')'
    describe command(<<-EOF

      function Get-NetFramework {
      $caller_class = 'VerisonHelper'

Add-Type -TypeDefinition @"

using System;
using Microsoft.Win32;
public class ${caller_class}  {

	private string version;
	public string Version {
		get { return version; }
	}
	const string subkey = @"SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full\\";

	public ${caller_class}() {

		using (var ndpKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry32).OpenSubKey(subkey)) {
			if (ndpKey != null && ndpKey.GetValue("Release") != null) {
				version = CheckFor45PlusVersion((int)ndpKey.GetValue("Release"));
				Console.Error.WriteLine(String.Format(".NET Framework Version: {0}", version));
			} else {
				Console.Error.WriteLine(".NET Framework Version 4.5 or later is not detected.");
			}
		}
	}

	// Checking the version using >= enables forward compatibility.
	private string CheckFor45PlusVersion(int releaseKey) {
		if (releaseKey >= 528040)
			return "4.8";
		if (releaseKey >= 461808)
			return "4.7.2";
		if (releaseKey >= 461308)
			return "4.7.1";
		if (releaseKey >= 460798)
			return "4.7";
		if (releaseKey >= 394802)
			return "4.6.2";
		if (releaseKey >= 394254)
			return "4.6.1";
		if (releaseKey >= 393295)
			return "4.6";
		if (releaseKey >= 379893)
			return "4.5.2";
		if (releaseKey >= 378675)
			return "4.5.1";
		if (releaseKey >= 378389)
			return "4.5";
		// This code should never execute. A non-null release key should mean
		// that 4.5 or later is installed.
		return "No 4.5 or later version detected";
	}
}
"@ -ReferencedAssemblies 'mscorlib.dll'
# NOTE: no indenting of the above line
$o = new-object -typename $caller_class
return $o.Version

      }
    write-output (Get-NetFramework)
    # NOTE: without parenthesis, will print 'Get-NetFramework' verbatim

     
    EOF
    ) do
      its(:stdout) { should match /^#{versions_re}$/ }
    end
  end
end
