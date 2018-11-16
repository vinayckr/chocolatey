$PackageName=Read-Host -Prompt 'Package Name'
$PackageVersion = Read-Host -Prompt 'Version'
$BinaryPath = Read-Host -Prompt 'Exact Path for binary'
$BinaryFileName = Read-Host -Prompt 'Binary File Name inlcuding extension'
$installerExtension = Read-Host -Prompt 'Enter Installer type example: Exe or msi'
$SilentArguments = Read-Host -Prompt 'enter silent arguments'
$AuthorName = Read-Host -Prompt 'Enter Author Name'
choco new $PackageName
$installScriptfile = '.\'+$PackageName+'\tools\chocolateyinstall.ps1'
$xmlFile = '.\'+$PackageName+'\'+$PackageName+'.nuspec'
$binaryFile = '.\'+$PackageName+'\tools\'+$BinaryFileName
Write-Output $PackageName
Write-Output $PackageVersion
Write-Output $BinaryPath
Write-Output $BinaryFileName
Write-Output $installScriptfile
Write-Output $xmlFile

robocopy /E $BinaryPath .\$PackageName\tools\
$binarHash = Get-FileHash $binaryFile
Write-Output $binarHash.Hash
$binaryFileHashValue = Write-Output $binarHash.Hash
$nuspecFile = @"
<?xml version=`"1.0`" encoding=`"utf-8`"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>{0}</id>
    <title>{0} (Install)</title>
    <version>{1}</version>
    <authors>{2}</authors>
    <owners>BNY Mellon</owners>
    <description>Installation of package {0}</description>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
"@ -f $PackageName, $PackageVersion, $AuthorName

$installPSfileString= @"
`$ErrorActionPreference = 'Stop';

`$packageName= '$PackageName'
`$toolsDir   = `$(Split-Path -parent `$MyInvocation.MyCommand.Definition)
`$fileLocation = Join-Path `$toolsDir '$BinaryFileName'

`$packageArgs = `@{
  packageName   = `$packageName
  fileType      = `$installerExtension
  file         = `$fileLocation
  checksum      = '$BinaryFileHashValue'
  checksumType  = 'sha256' 
  silentArgs    = "$SilentArguments"
  validExitCodes= `@(0)
}

Install-ChocolateyPackage `@packageArgs
"@

Write-Output $nuspecFile
Write-Output $installPSfileString

$nuspecFile | out-file -filepath $xmlFile
$installPSfileString | out-file -filepath $installScriptfile

choco pack $xmlFile
