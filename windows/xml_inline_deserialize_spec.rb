# origin: http://www.cyberforum.ru/powershell/thread2399334.html
# a lot of alternatives, varying cryptic
# use
# <?xml version="1.0" encoding="utf-8"?>
#
#<Package xmlns="http://schemas.microsoft.com/appx/2010/manifest">
#
#  <Identity Name="winstore"
#            ProcessorArchitecture="neutral"
#            Publisher="CN=Microsoft Windows, O=Microsoft Corporation, L=Redmond, S=Washington, C=US"
#            Version="1.0.0.0"
#            ResourceId="neutral" />
#
#  <Properties>
#    <Framework>false</Framework>
#    <PublisherDisplayName>ms-resource:PublisherDisplayName</PublisherDisplayName>
#    <Description>ms-resource:Description</Description>
#    <DisplayName>ms-resource:DisplayName</DisplayName>
#    <Logo>images\logo.png</Logo>
#  </Properties>
#
#  <Prerequisites>
#    <OSMinVersion>6.3.0</OSMinVersion>
#    <OSMaxVersionTested>6.3.0</OSMaxVersionTested>
#  </Prerequisites>
#
#  <Resources>
#    <Resource Language="en-us"/>
#  </Resources>
#
#  <Applications>
#    <Application Id="Windows.Store" StartPage="WinStore.htm">
#      <VisualElements DisplayName="ms-resource:TileDisplayName" Description="ms-resource:Description"
#                      Logo="Logo.png" SmallLogo="SmallLogo.png"
#                      ForegroundText="dark" BackgroundColor="#F2F2F2">
#        <SplashScreen Image="SplashScreen.png" BackgroundColor="#F2F2F2" />
#      </VisualElements>
#      <ApplicationContentUriRules>
#        <Rule Type="include" Match="https://*.microsoft.com" />
#        <Rule Type="include" Match="https://*.*.microsoft.com" />
#        <Rule Type="include" Match="https://*.*.*.microsoft.com" />
#        <Rule Type="include" Match="https://buy.live.com" />
#        <Rule Type="include" Match="https://buy.live-int.com" />
#      </ApplicationContentUriRules>
#    </Application>
#  </Applications>
#
#</Package>
#
# apt-get install -qqy libxml2-utils

[xml]$xml = Get-Content 'C:\Windows\WinStore\AppxManifest.xml'

$obj_list = @()

foreach ($package in $xml.GetElementsByTagName('Package')) {
  foreach ($property in $package.GetElementsByTagName('Properties')) {
    $obj_list += [PSCustomObject][ordered]@{
      'Framework' = $property.Framework
      # http://www.cyberforum.ru/powershell/thread2401922.html
      # only works when DOM node has some attributes like e.g.
      #       <Logo attribute="">images\logo.png</Logo>
      # fails for
      # 'broken'  = $property.Logo.'#text'
      'Logo'      = $property.Logo
    }
  }
}

$obj_list | format-list

xml_data = <<-EOF
<?xml version="1.0" encoding="windows-1251"?>
<DisplayDefinitionTable>
  <rows>
    <row>
      <object_tag tag="37085" uid="hrfpbFO9IzpdMD"/>
      <row_element column="0" component_tag="37501" property_name="item_id">000130</row_element>
      <row_element column="7" component_tag="35869" property_name="name">dba</row_element>
      <logo>images\logo.png</logo>
    </row>
  </rows>
  <SearchCriteriaTitle>Search Criteria Used: (1 Objects found)</SearchCriteriaTitle>
</DisplayDefinitionTable>

EOF

[xml]$xml = get-content 'test.xml' -enc Default

$data = $xml.SelectNodes('//row') |foreach-object {
  $obj = New-Object PSCustomObject
  $_.row_element |foreach-object {Add-Member -Type NoteProperty -Name $_.property_name -Value $_.'#Text' -InputObject $obj}
  $_.Logo | foreach-object {
        Add-Member -Type NoteProperty -Name 'Logo' -Value $_.'#Text' -InputObject $obj
  }
  $obj
}
$data | format-list
