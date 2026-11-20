param([switch]$SkipTests)
$ErrorActionPreference = 'Stop'
$project6 = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $project6
$maven6 = Get-Command mvn.cmd -ErrorAction SilentlyContinue
$mavenPath6 = if ($maven6) { $maven6.Source } else { Join-Path $project6 '.tools/apache-maven-3.9.9/bin/mvn.cmd' }
if (!(Test-Path -LiteralPath $mavenPath6)) { throw 'Install Maven 3.9+ and add mvn.cmd to PATH.' }
$args6 = @('-B', "-Dmaven.repo.local=$project6/.tools/m2", 'clean', 'package')
if ($SkipTests) { $args6 += '-DskipTests' }
& $mavenPath6 @args6
if ($LASTEXITCODE -ne 0) { throw 'Maven build failed.' }

