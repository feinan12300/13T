param(
    [Parameter(Mandatory = $true)]
    [string]$Owner,

    [Parameter(Mandatory = $true)]
    [string]$Repo,

    [string]$Token = $env:GITHUB_TOKEN,
    [string]$Description = '13TANG LIVESHOW local project upload',
    [switch]$Private,
    [switch]$CreateIfMissing
)

if (-not $Token) {
    throw 'GitHub token is required. Set the environment variable GITHUB_TOKEN or pass -Token.'
}

$baseUrl = 'https://api.github.com'
$headers = @{ 
    Authorization = "token $Token";
    Accept = 'application/vnd.github+json';
    'User-Agent' = 'PowerShell-GitHub-Upload';
}

function Invoke-GitHubApi {
    param(
        [string]$Method,
        [string]$Uri,
        $Body = $null
    )

    if ($Body) {
        return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers -Body ($Body | ConvertTo-Json -Depth 10) -ContentType 'application/json'
    }

    return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers
}

function Get-AuthenticatedUser {
    return Invoke-GitHubApi -Method Get -Uri "$baseUrl/user"
}

function Ensure-Repo {
    try {
        Invoke-GitHubApi -Method Get -Uri "$baseUrl/repos/$Owner/$Repo" | Out-Null
        Write-Host "Repository '$Owner/$Repo' already exists."
        return
    } catch {
        if (-not $CreateIfMissing) {
            throw "Repository '$Owner/$Repo' does not exist. Use -CreateIfMissing to create it."
        }
    }

    $account = Get-AuthenticatedUser
    if ($account.login -ieq $Owner) {
        $body = @{ name = $Repo; description = $Description; private = $Private.IsPresent }
        Invoke-GitHubApi -Method Post -Uri "$baseUrl/user/repos" -Body $body | Out-Null
        Write-Host "Created repository '$Owner/$Repo' in your account."
    } else {
        $body = @{ name = $Repo; description = $Description; private = $Private.IsPresent }
        Invoke-GitHubApi -Method Post -Uri "$baseUrl/orgs/$Owner/repos" -Body $body | Out-Null
        Write-Host "Created repository '$Owner/$Repo' in organization '$Owner'."
    }
}

function Upload-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$RepoPath
    )

    $contentBytes = [System.IO.File]::ReadAllBytes($FilePath)
    $contentBase64 = [System.Convert]::ToBase64String($contentBytes)
    $payload = @{ message = "Add $RepoPath"; content = $contentBase64 }

    try {
        $existing = Invoke-GitHubApi -Method Get -Uri "$baseUrl/repos/$Owner/$Repo/contents/$RepoPath"
        if ($existing.sha) {
            $payload.sha = $existing.sha
            $payload.message = "Update $RepoPath"
        }
    } catch {
        # File does not exist yet
    }

    Invoke-GitHubApi -Method Put -Uri "$baseUrl/repos/$Owner/$Repo/contents/$RepoPath" -Body $payload | Out-Null
    Write-Host "Uploaded: $RepoPath"
}

$scriptDir = Get-Location
$files = Get-ChildItem -Path $scriptDir -File -Recurse | Where-Object { $_.FullName -notmatch '\\.git\\' }

if (-not $files) {
    throw 'No files found to upload.'
}

Ensure-Repo

foreach ($file in $files) {
    $repoPath = $file.FullName.Substring($scriptDir.Path.Length + 1).Replace('\', '/')
    Upload-File -FilePath $file.FullName -RepoPath $repoPath
}

Write-Host 'Upload complete!'
