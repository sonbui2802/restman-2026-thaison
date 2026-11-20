param([string]$TomcatHome = $env:CATALINA_HOME, [int]$Port = 8080, [switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
$project6 = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $project6
if (!$TomcatHome) { $TomcatHome = Join-Path $project6 '.tools/apache-tomcat-9.0.98' }
$TomcatHome = [IO.Path]::GetFullPath($TomcatHome)
if (!(Test-Path -LiteralPath "$TomcatHome/bin/catalina.bat")) { throw 'Set CATALINA_HOME to Apache Tomcat 9.' }
if ($Port -lt 1024 -or $Port -gt 65535) { throw 'Invalid HTTP port.' }
if (!$SkipBuild) { & "$PSScriptRoot/build.ps1" }
$war6 = Join-Path $project6 'target/restman6.war'
if (!(Test-Path -LiteralPath $war6)) { throw 'Build target/restman6.war first.' }
$base6 = Join-Path $project6 '.runtime/tomcat'
foreach ($folder6 in @('conf','logs','temp','webapps','work')) {
    New-Item -ItemType Directory -Force (Join-Path $base6 $folder6) | Out-Null
}
if (!(Test-Path -LiteralPath "$base6/conf/web.xml")) { Copy-Item -Path "$TomcatHome/conf/*" -Destination "$base6/conf" -Recurse }
$server6 = [IO.File]::ReadAllText("$TomcatHome/conf/server.xml")
$server6 = $server6.Replace('<Server port="8005"', '<Server port="-1"')
$server6 = $server6.Replace('<Connector port="8080"', "<Connector address=`"127.0.0.1`" port=`"$Port`"")
[IO.File]::WriteAllText("$base6/conf/server.xml", $server6)
Copy-Item -LiteralPath $war6 -Destination "$base6/webapps/restman6.war" -Force
$env:CATALINA_HOME = $TomcatHome
$env:CATALINA_BASE = $base6
# Database settings are read by DAO6 from src/main/resources/db.properties.
Write-Host "Open http://localhost:$Port/restman6/"
& "$TomcatHome/bin/catalina.bat" run

