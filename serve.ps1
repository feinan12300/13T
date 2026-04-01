param(
    [int]$Port = 8000,
    [string]$Root = "."
)

$Root = Resolve-Path $Root
Set-Location $Root
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
$listener.Start()
Write-Host "Serving http://localhost:$Port/"
Write-Host "Root: $Root"

function Get-MediaType($path) {
    switch ([IO.Path]::GetExtension($path).ToLower()) {
        ".css" { "text/css" }
        ".js" { "application/javascript" }
        ".json" { "application/json" }
        ".svg" { "image/svg+xml" }
        ".png" { "image/png" }
        ".jpg" { "image/jpeg" }
        ".jpeg" { "image/jpeg" }
        ".gif" { "image/gif" }
        ".webp" { "image/webp" }
        default { "text/html; charset=utf-8" }
    }
}

while ($true) {
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()
    $reader = [System.IO.StreamReader]::new($stream)
    $requestLine = $reader.ReadLine()
    if (-not $requestLine) {
        $stream.Close()
        $client.Close()
        continue
    }

    while ($reader.Peek() -ge 0) {
        $line = $reader.ReadLine()
        if ($line -eq '') { break }
    }

    $parts = $requestLine.Split(' ')
    $relative = $parts[1].TrimStart('/')
    if (-not $relative) { $relative = 'index.html' }
    $file = Join-Path $Root $relative

    if (-not (Test-Path $file -PathType Leaf)) {
        $body = [Text.Encoding]::UTF8.GetBytes("404 Not Found")
        $header = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain; charset=utf-8`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
        $headerBytes = [Text.Encoding]::ASCII.GetBytes($header)
        $stream.Write($headerBytes, 0, $headerBytes.Length)
        $stream.Write($body, 0, $body.Length)
        $stream.Close()
        $client.Close()
        continue
    }

    $bytes = [IO.File]::ReadAllBytes($file)
    $contentType = Get-MediaType $file
    $header = "HTTP/1.1 200 OK`r`nContent-Type: $contentType`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
    $headerBytes = [Text.Encoding]::ASCII.GetBytes($header)
    $stream.Write($headerBytes, 0, $headerBytes.Length)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Close()
    $client.Close()
}
