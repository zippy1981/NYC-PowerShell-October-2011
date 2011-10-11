if ([intptr]::size -eq 8) { $mongoDriverPath = (Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v3.5\AssemblyFoldersEx\MongoDB CSharpDriver 1.0").'(default)'; }
else { $mongoDriverPath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\.NETFramework\v3.5\AssemblyFoldersEx\MongoDB CSharpDriver 1.0").'(default)'; }
Add-Type -Path "$($mongoDriverPath)\MongoDB.Bson.dll";
Add-Type -Path "$($mongoDriverPath)\MongoDB.Driver.dll";

# See http://blogs.msdn.com/b/powershell/archive/2007/06/19/get-scriptdirectory.aspx
function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

$scriptFolder = Get-ScriptDirectory

Add-Type -Path "$($scriptFolder)\..\TomTom.Tools\bin\Debug\TomTom.Tools.dll"

[TomTom.Tools.OV2Parser] $parser = New-Object TomTom.Tools.OV2Parser

# Extract
$pois = $parser.ReadOV2("$($scriptFolder)\..\data\Wal-Mart_United States & Canada.ov2")
$pois | Out-GridView

# Transform
$cleansedPois = $pois | ForEach-Object{
	$storeTypeSeperator = $_.Name.IndexOf(" - ")
	$storeNumberIndex = $_.Name.IndexOf(",")
	$poundIndex = $_.Name.IndexOf("#")
	
	@{
		StoreType = $_.Name.SubString(0, $storeTypeSeperator - 1);
		StoreName = $_.Name.SubString($storeTypeSeperator + 4,  $storeNumberIndex - $storeTypeSeperator - 4);
		StoreNumber = $_.Name.SubString($poundIndex + 1).Trim(';');
		Coordinates = $_.Lat, $_.Long;
	}
}

# Load
$db = [MongoDB.Driver.MongoDatabase]::Create('mongodb://localhost/powershell')
$collection = $db['walmarts']
$collection.Drop()
$cleansedPois | ForEach-Object { $collection.Insert($_, [MongoDB.Driver.SafeMode]::True) } | Out-GridView

# Build Indexes
$indexKeys = (New-Object MongoDB.Driver.Builders.IndexKeysBuilder).GeoSpatial('Coordinates');
$collection.EnsureIndex($indexKeys);