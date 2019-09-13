#powershell.exe -ExecutionPolicy Unrestricted -Command .\\installvstsagent.ps1 -vstsAccount youjinglee -personalAccessToken wbobozlizkfv64i2mbhknutcmei2d2po7tp2fukftvvn3osecc2a -AgentName LandingVM -PoolName 'Azure TestingWeb'

[CmdletBinding()]
Param(
#[Parameter(Mandatory=$true)]$VSTSAccount,
#[Parameter(Mandatory=$true)]$PersonalAccessToken,
[Parameter(Mandatory=$true)]$AgentName
#[Parameter(Mandatory=$true)]$PoolName
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$VSTSAccount = "youjinglee"
$PersonalAccessToken = "3u3jqbpzn4yjnltgksqeoprajfro3kttmscobeam3wybt2tlo5wa"
#$AgentName = "AgentDeployTest"
$PoolName = "Azure TestingWeb"


# Temporary folder
$agentTempFolderName = Join-Path $env:temp ([System.IO.Path]::GetRandomFileName()).replace('.','')
New-Item -ItemType Directory -Force -Path $agentTempFolderName
Write-Verbose $agentTempFolderName


$retryCount = 3
$retries = 1
# Download agent files
do {
    try {

        $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/Microsoft/vsts-agent/releases"
        $latestRelease = $latestRelease | Where-Object assets -ne $null | Sort-Object created_at -Descending | Select-Object -First 1
        $assetsURL = ($latestRelease.assets).browser_download_url
        $latestReleaseDownloadUrl = ((Invoke-RestMethod -Uri $assetsURL) -match 'win-x64').downloadurl
        Invoke-WebRequest -Uri $latestReleaseDownloadUrl -Method Get -OutFile "$agentTempFolderName\agent.zip"
        Write-Verbose "Downloaded agent successfully on attempt $retries" -verbose
        break
    } catch {
        $exceptionText = ($_ | Out-String).Trim()
        Write-Verbose "Exception occurred downloading agent: $exceptionText in try number $retries" -verbose
        $retries++
        Start-Sleep -Seconds 30
    }
} while ($retries -le $retryCount)


#Devops URL
$serverUrl = "https://dev.azure.com/$VSTSAccount"

# New Directory
$agentInstallationPath = Join-Path "C:" $AgentName
New-Item -ItemType Directory -Force -Path $agentInstallationPath
Push-Location -Path $agentInstallationPath
Write-Verbose "New directory created"

# Copy to new directory
$destShellFolder = (new-object -com shell.application).namespace("$agentInstallationPath")
$destShellFolder.CopyHere((new-object -com shell.application).namespace("$agentTempFolderName\agent.zip").Items(),16)
Write-Verbose "Copy to new directory done"

# Removing the ZoneIdentifier from files downloaded from the internet so the plugins can be loaded
# Don't recurse down _work or _diag, those files are not blocked and cause the process to take much longer
Write-Verbose "Unblocking files" -verbose
Get-ChildItem -Recurse -Path $agentInstallationPath | Unblock-File | out-null
Write-Verbose "Unblock done"

# Locate the config.cmd"
$agentConfigPath = [System.IO.Path]::Combine($agentInstallationPath, 'config.cmd')
Write-Verbose "Agent Location = $agentConfigPath" -Verbose
if (![System.IO.File]::Exists($agentConfigPath))
{
    Write-Error "File not found: $agentConfigPath" -Verbose
    return
}

#Pat
#$pat = $PersonalAccessToken

.\config.cmd --unattended --url $serverUrl --auth PAT --token $PersonalAccessToken --pool $PoolName --agent $AgentName --runasservice

Pop-Location

Write-Verbose "Agent install output: $LASTEXITCODE" -Verbose

Write-Verbose "Exiting InstallVSTSAgent.ps1" -Verbose