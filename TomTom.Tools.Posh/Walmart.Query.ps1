[string] $mongoDriverPath;
if ([intptr]::size -eq 8) { $mongoDriverPath = (Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v3.5\AssemblyFoldersEx\MongoDB CSharpDriver 1.0").'(default)'; }
else { $mongoDriverPath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\.NETFramework\v3.5\AssemblyFoldersEx\MongoDB CSharpDriver 1.0").'(default)'; }
Add-Type -Path "$($mongoDriverPath)\MongoDB.Bson.dll";
Add-Type -Path "$($mongoDriverPath)\MongoDB.Driver.dll";

$webclient = New-Object System.Net.WebClient
#$results = [xml]$webclient.DownloadString('http://nominatim.openstreetmap.org/search/us/ny/new%20york/1290%20Avenue%20of%20the%20Americas?format=xml&polygon=0&addressdetails=0');
#$results = [xml]$webclient.DownloadString('http://nominatim.openstreetmap.org/search/us/nj/jersey%20city/grove%20street/303?format=xml&polygon=0&addressdetails=1');
$results = [xml]$webclient.DownloadString('http://nominatim.openstreetmap.org/search/us/ny/commack/mall%20drive/47?format=xml&polygon=0&addressdetails=1');

$query = New-Object MongoDB.Driver.QueryDocument(@{
	Coordinates = @{
		'$nearSphere' = [MongoDb.Bson.BsonArray] ([float]$results.searchresults.place.lat, [float] $results.searchresults.place.lon) 
	};
	StoreType = 'Wal-Mart';
});

$db = [MongoDB.Driver.MongoDatabase]::Create('mongodb://localhost/powershell')
$collection = $db['walmarts']
$collection.FindOne($query);