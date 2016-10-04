[CmdletBinding()]
param (
        [switch] $UpdateTools,
        [switch] $Download,
        [switch] $Test
)

Function WebCall ([System.URI]$GetUri, [System.Int32]$TimeOutMin, [System.IO.FileInfo]$OutFile)
{   #Using System.Net.Http (instead of System.Net.WebClient) so this can work on Nano too. 
    if (-not($GetUri -as [System.URI]).AbsoluteURI) {throw "Invalid URL: '$GetUri'"}
    Add-Type -AssemblyName 'System.Net.Http'
    $handler = New-Object System.Net.Http.HttpClientHandler
    $client  = New-Object System.Net.Http.HttpClient($handler)
    $client.Timeout  = New-Object System.TimeSpan(0, $TimeOutMin, 0)
    $cancelTokenSource = [System.Threading.CancellationTokenSource]::new()
    $responseMsg = $client.GetAsync([System.Uri]::new($GetUri), $cancelTokenSource.Token)
    Write-Host "Making WebRequest to '$GetUri'..."
    $responseMsg.Wait()
    $client.Dispose();$cancelTokenSource.Dispose();$handler.Dispose()
    if (!$responseMsg.IsCanceled)
    {  
        $response = $responseMsg.Result
        if ($response.IsSuccessStatusCode)
        {
            if ($OutFile) 
            {
                Write-Host ("Writing response to '"+($Outfile.FullName)+"'...")
                $downloadedFileStream = [System.IO.FileStream]::new($OutFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
                $copyStreamOp = $response.Content.CopyToAsync($downloadedFileStream)
                $copyStreamOp.Wait()
                $downloadedFileStream.Close()
                if ($copyStreamOp.Exception -ne $null)
                {
                    throw $copyStreamOp.Exception
                }
                $client.Dispose();$cancelTokenSource.Dispose();$handler.Dispose()
                return $OutFile
            } else {
                $client.Dispose();$cancelTokenSource.Dispose();$handler.Dispose()
                Write-Host "WebRequest completed successfully"
                return $response
            }
        } else {
            write-verbose ($response.ToString())
            throw "Request to '$GetUri' failed"
        }        
    } else {
        write-error "Request to '$GetUri' timed out."
        return $responseMsg
    }
}
Function Get-LatestPsZip ()
{
  $gitUri = 'https://github.com/PowerShell/PowerShell/releases/latest/'
  $response=WebCall -GetUri $gitUri -TimeOutMin 3 -ErrorAction Stop
  $gitTag = ($response.RequestMessage.RequestUri.AbsoluteUri.split("/"))[-1].TrimStart('v')
  $downloadFile = 'powershell-' + $gitTag + '-win10-x64.zip'
  Write-Host ("Latest release is '"+$downloadFile+"'")
  $downloadUri = ($response.RequestMessage.RequestUri.AbsoluteUri.Replace('tag','download')) + '/' + $downloadFile
  [System.Io.DirectoryInfo]$destinationPath = $env:CoreOutput
  if ([String]$(Get-Content -Path $destinationPath\.dlsource.txt -ErrorAction Ignore)  -eq $downloadUri)
  {
    Write-Host ("Latest release is already present in '"+$destinationPath.FullName+"'.  Exiting...")
    return "no new build to test" #no-op and exit
  } else {
    [System.Io.FileInfo]$tempFile = [System.IO.Path]::GetTempFileName()
    $response=WebCall -GetUri $downloadUri -TimeOutMin 30 -OutFile $tempFile -ErrorAction Stop
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if (Test-Path $destinationPath)
    {
        Write-Host ("Removing existing files under '"+$destinationPath.FullName+"'...")
        Remove-Item -Path $destinationPath -Force -Recurse -ErrorAction Stop 
    }
    [System.Io.DirectoryInfo]$destinationPath = New-Item -Path $destinationPath -ItemType Directory -Force -ErrorAction Stop
    Write-Host ("Extracting new files to '"+$destinationPath.FullName+"'...")
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempFile,$destinationPath)
    Write-Host ("Deleting tmp file '"+$tempFile.FullName+"'...")
    Remove-Item $tempFile -ErrorAction Continue
    Write-Host ("Logging download source URL to '"+($destinationPath.FullName + '\.dlsource.txt')+"'.")
    $downloadUri | out-file -FilePath ($destinationPath.FullName + '\.dlsource.txt')
    return ("New build successfully downloaded to '"+$destinationPath.FullName+"'.")
  }
}

$Global:buildConfiguration = 'Release'
$repoRoot=Join-Path $PSScriptRoot '..'
Import-Module (Join-Path $repoRoot 'build.psm1')
Import-Module .\tools\Appveyor.psm1
$env:CoreOutput = Split-Path -Parent (Get-PSOutput -Options (New-PSOptions -Publish -Configuration $buildConfiguration))
$ErrorActionPreference="Stop"
if ($UpdateTools) {Invoke-AppveyorInstall}
if ($Download) {Get-LatestPsZip}
if ($Test) {Invoke-AppveyorTest}
