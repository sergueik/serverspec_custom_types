require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine

context 'NPOI legacy PowerPoint' do

  describe command(<<-'POWERSHELL'
$ErrorActionPreference = 'Stop'

$root = 'C:\uru'
$filename = Join-Path $root 'file_example_PPT_500kB.ppt'

$assemblyNames = @(
  'ICSharpCode.SharpZipLib.dll',
  'NPOI.OOXML.dll',
  'NPOI.OpenXml4Net.dll',
  'NPOI.dll'
)

$assemblyPaths = @()

foreach ($name in $assemblyNames) {
  $path = Join-Path $root $name

  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw ('Required assembly not found: {0}' -f $path)
  }

  [void][Reflection.Assembly]::LoadFrom($path)
  $assemblyPaths += $path
}

if (-not (Test-Path -LiteralPath $filename -PathType Leaf)) {
  throw ('Test presentation not found: {0}' -f $filename)
}

$references = @($assemblyPaths) + @(
  'System.Windows.Forms.dll',
  'System.Drawing.dll',
  'System.Data.dll',
  'System.Collections.dll',
  'System.xml.dll',
  'System.Xml.Linq.dll'
)

$source = @'
using System;
using System.Collections.Generic;
using System.IO;
using NPOI;
using NPOI.OpenXml4Net.OPC;
using NPOI.Util;

namespace LegacyPptProbe
{
    public sealed class ProbeDocument : POIXMLDocument
    {
        public ProbeDocument(OPCPackage package) : base(package)
        {
        }

        public void Parse(POIXMLFactory factory)
        {
            Load(factory);
        }

        public override List<PackagePart> GetAllEmbedds()
        {
            throw new NotSupportedException(
                "Embedded-part enumeration is not needed by this probe.");
        }
    }

    public sealed class TestFactory : POIXMLFactory
    {
        protected override POIXMLRelation GetDescriptor(
            string relationshipType)
        {
            return null;
        }

        protected override POIXMLDocumentPart CreateDocumentPart(
            Type cls, Type[] classes, object[] values)
        {
            throw new NotSupportedException(
                "Unexpected call to the custom document-part constructor.");
        }
    }

    public static class Harness
    {
        public static string LastStage { get; private set; }

        public static Exception CaptureFailure(string filename)
        {
            LastStage = "File.OpenRead";

            try
            {
                using (FileStream stream = File.OpenRead(filename))
                {
                    LastStage = "PackageHelper.Open";
                    OPCPackage package = PackageHelper.Open(stream);

                    ProbeDocument doc = new ProbeDocument(package);

                    try
                    {
                        LastStage = "doc.Parse(TestFactory)";
                        doc.Parse(new TestFactory());
                        return null;
                    }
                    finally
                    {
                        doc.Close();
                    }
                }
            }
            catch (Exception ex)
            {
                return ex;
            }
        }
    }
}
'@

Add-Type -TypeDefinition $source `
  -Language CSharp `
  -ReferencedAssemblies $references `
  -ErrorAction Stop

$failure = [LegacyPptProbe.Harness]::CaptureFailure($filename)

if ($null -eq $failure) {
  Write-Output 'ExceptionType=<none>'
  Write-Output 'ExceptionMessage=<none>'
} else {
  Write-Output ('ExceptionType={0}' -f $failure.GetType().FullName)
  Write-Output ('ExceptionMessage={0}' -f $failure.Message)
}

Write-Output ('FailureStage={0}' -f [LegacyPptProbe.Harness]::LastStage)
POWERSHELL
  ) do


    its(:stdout) do
      should match /ExceptionType=ICSharpCode\.SharpZipLib\.Zip\.ZipException/
    end

    its(:stdout) do
      should match /ExceptionMessage=Wrong Local header signature: 0xE011CFD0/
    end

    its(:stdout) do
      should match /FailureStage=PackageHelper\.Open/
    end
    # will fail
    #  4 examples, 1 failure
    its(:exit_status) { should eq 0 }

  end
end

# TODO: add the 'file'-like expectation:
# signature = File.open(filename, 'rb') { |file| file.read(8) }
# 
# signature.unpack('H*').first.should == 'd0cf11e0a1b11ae1'
#
