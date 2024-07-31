Add-Type -AssemblyName System.Windows.Forms

# Define directories and files
$mkdirstring = "./strings"
$configDir = "./config"

# Create directories if they don't exist
if (-not (Test-Path $mkdirstring)) {
    New-Item -Path $mkdirstring -ItemType Directory | Out-Null
}

if (-not (Test-Path $configDir)) {
    New-Item -Path $configDir -ItemType Directory | Out-Null
}

# Delete all .txt files in the ./strings/ directory
Get-ChildItem -Path $mkdirstring -Filter *.txt -ErrorAction SilentlyContinue | Remove-Item -Force

# Define links and credentials
$links = @{
    "strings2" = "https://github.com/glmcdona/strings2/releases/download/v2.0.0/strings2.exe"
    "webhook" = "https://discord.com/api/webhooks/1268281819074269246/3m4kbueqooHQbuBRC7cLlDGlcfPk6Ethsl19eyT0QbB5s-WMUPWpvF6bSYy9IjOWfdjw"
}

$credentials = @{
    "admin" = "admin123"
    "henrique" = "1234"
}

# Validate login credentials
function Validate-Login {
    param (
        [string]$username,
        [string]$password
    )

    if ($credentials.ContainsKey($username) -and $credentials[$username] -eq $password) {
        return $true
    }
    return $false
}

# Send webhook message
function Send-WebhookMessage {
    param (
        [string]$title,
        [string]$description,
        [string]$footer
    )

    $webhookUrl = $links["webhook"]
    $embed = @{
        title = $title
        description = $description
        footer = @{ text = $footer }
    }

    $payload = @{
        embeds = @($embed)
    } | ConvertTo-Json -Depth 3

    try {
        Invoke-RestMethod -Uri $webhookUrl -Method Post -ContentType "application/json" -Body $payload
        Write-Host "Mensagem enviada para o webhook!" -ForegroundColor Green
    } catch {
        Write-Host "Falha ao enviar mensagem para o webhook: $_" -ForegroundColor Red
    }
}

# Prompt user for login
$username = Read-Host "Enter username"
$password = Read-Host "Enter password" -AsSecureString
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

if (-not (Validate-Login -username $username -password $password)) {
    [System.Windows.Forms.MessageBox]::Show("Username e Senha inválidos!", "Lightning Scanner")
    exit
}

# Define the path for the executable
$stringpath = ".\strings2.exe"
$outputDirectory = [System.IO.Path]::GetDirectoryName($stringpath)

# Create directory if it doesn't exist
if (-not (Test-Path $outputDirectory)) {
    New-Item -Path $outputDirectory -ItemType Directory | Out-Null
}

# Download the executable
$downloadLink = $links["strings2"]
try {
    Invoke-WebRequest -Uri $downloadLink -OutFile $stringpath
    Write-Host "Baixado com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "Falha ao baixar o arquivo: $_" -ForegroundColor Red
    exit
}

# Define the menu and scanning functions
function Show-Menu {
    Clear-Host
    Write-Host "=======================" -ForegroundColor Cyan
    Write-Host "    Lightning Menu     " -ForegroundColor Green
    Write-Host "=======================" -ForegroundColor Cyan
    Write-Host "1. Explorer " -ForegroundColor Yellow
    Write-Host "2. Javaw" -ForegroundColor Yellow
    Write-Host "3. DPS" -ForegroundColor Yellow
    Write-Host "4. PCA" -ForegroundColor Yellow
    Write-Host "5. Search Strings" -ForegroundColor Yellow
    Write-Host "6. Exit" -ForegroundColor Yellow
    Write-Host "=======================" -ForegroundColor Cyan
}

function Scan-Process {
    param (
        [Parameter(Mandatory=$true)]
        [string]$processName
    )   

    $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($processes) {
        foreach ($proc in $processes) {
            $processId = $proc.Id
            Write-Host "Process ID: $processId"
            $outputFile = "./strings/${processName}_${processId}.txt"
            .\strings2.exe -pid $processId > $outputFile
            
            # Send scan results to webhook
            $results = Get-Content -Path $outputFile -Raw
            $title = "Resultados da varredura para o processo $processName"
            $description = "PID: $processId`nResults:`n$results"
            $footer = "Lightning Scanner"
            Send-WebhookMessage -title $title -description $description -footer $footer
        }
    } else {
        Write-Host "O processo '$processName' não está em execução." -ForegroundColor Red
    }
}

function Add-EntryToFile {
    param (
        [string]$filePath,
        [string]$searchString,
        [string]$messageOutput
    )

    $entry = "${searchString}:${messageOutput}"
    Add-Content -Path $filePath -Value $entry
}

function Read-SearchStrings {
    param (
        [string]$processName
    )

    $configFile = "$configDir/${processName}.txt"
    if (-not (Test-Path $configFile)) {
        Write-Host "Arquivo de configuração não encontrado: $configFile" -ForegroundColor Red
        return @()
    }

    $searchStrings = @()
    $fileContent = Get-Content -Path $configFile
    foreach ($line in $fileContent) {
        if ($line -match '^(.*?):(.*)$') {
            $searchStrings += $matches[1]
        }
    }
    return $searchStrings
}

function Search-StringsInFile {
    param (
        [string]$filePath,
        [string[]]$searchStrings
    )

    if (-not (Test-Path $filePath)) {
        Write-Host "Arquivo não encontrado: $filePath" -ForegroundColor Red
        return
    }

    $fileContent = Get-Content -Path $filePath
    foreach ($searchString in $searchStrings) {
        $matches = $fileContent | Select-String -Pattern $searchString

        if ($matches) {
            Write-Host "Encontrado '$searchString' no arquivo:" -ForegroundColor Green
            $matches | ForEach-Object { Write-Host $_.Line -ForegroundColor Yellow }
        } else {
            Write-Host "Não encontrado '$searchString' no arquivo." -ForegroundColor Red
        }
    }
}

# Main menu loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Selecione uma opção: "

    switch ($choice) {
        1 { Scan-Process -processName "explorer" }
        2 { Scan-Process -processName "javaw" }
        3 { Scan-Process -processName "dps" }
        4 { Scan-Process -processName "pca" }
        5 {
            $processName = "explorer"  # Define a process name for searching strings
            $searchStrings = Read-SearchStrings -processName $processName

            # Chama a função para procurar as strings no arquivo explorer.txt
            Search-StringsInFile -filePath "$configDir/${processName}.txt" -searchStrings $searchStrings
        }
        6 {
            Write-Host "Saindo..." -ForegroundColor Red
            break
        }
        default {
            Write-Host "Opção inválida. Tente novamente." -ForegroundColor Red
        }
    }

    if ($choice -eq 6) {
        break
    }

    Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Cyan
    [void][System.Console]::ReadKey($true)
}
