# Script PowerShell para automatizar a instalação de AWS CLI, Node.js, Pulumi, Python, AWS SAM CLI e Serverless Framework no Windows 11

# Função para verificar se um comando está disponível
function CommandExists {
    param (
        [string]$command
    )
    $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}

# Instalação do AWS CLI
if (-not (CommandExists "aws")) {
    Write-Output "Instalando AWS CLI..."
    Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "AWSCLIV2.msi"
    Start-Process msiexec.exe -ArgumentList '/i AWSCLIV2.msi /quiet' -Wait
    Remove-Item -Path "AWSCLIV2.msi"
    Write-Output "AWS CLI instalado."
} else {
    Write-Output "AWS CLI já está instalado."
}

# Instalação do Node.js
if (-not (CommandExists "node")) {
    Write-Output "Instalando Node.js..."
    Invoke-WebRequest -Uri "https://nodejs.org/dist/v18.16.0/node-v18.16.0-x64.msi" -OutFile "nodejs.msi"
    Start-Process msiexec.exe -ArgumentList '/i nodejs.msi /quiet' -Wait
    Remove-Item -Path "nodejs.msi"
    Write-Output "Node.js instalado."
} else {
    Write-Output "Node.js já está instalado."
}

# Adicionando Node.js ao Path
$nodePath = "C:\Program Files\nodejs"
if (-not ($env:Path -like "*$nodePath*")) {
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$nodePath", [System.EnvironmentVariableTarget]::Machine)
    Write-Output "Node.js adicionado ao Path."
}

# Instalação do Pulumi
if (-not (CommandExists "pulumi")) {
    Write-Output "Instalando Pulumi..."
    Invoke-WebRequest -Uri "https://get.pulumi.com/releases/sdk/pulumi-v3.74.0-windows-x64.zip" -OutFile "pulumi.zip"
    Expand-Archive -Path "pulumi.zip" -DestinationPath "C:\Pulumi" -Force
    $pulumiPath = "C:\Pulumi\pulumi"
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Pulumi", [System.EnvironmentVariableTarget]::Machine)
    Remove-Item -Path "pulumi.zip"
    Write-Output "Pulumi instalado."
} else {
    Write-Output "Pulumi já está instalado."
}

# Adicionando Pulumi ao Path
if (-not ($env:Path -like "*$pulumiPath*")) {
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$pulumiPath", [System.EnvironmentVariableTarget]::Machine)
    Write-Output "Pulumi adicionado ao Path."
}

# Instalação do Python
if (-not (CommandExists "python")) {
    Write-Output "Instalando Python..."
    Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.10.4/python-3.10.4-amd64.exe" -OutFile "python.exe"
    Start-Process "python.exe" -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait
    Remove-Item -Path "python.exe"
    Write-Output "Python instalado."
} else {
    Write-Output "Python já está instalado."
}

# Adicionando Python ao Path
$pythonPath = "C:\Program Files\Python310"
if (-not ($env:Path -like "*$pythonPath*")) {
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$pythonPath", [System.EnvironmentVariableTarget]::Machine)
    Write-Output "Python adicionado ao Path."
}

# Instalação do AWS SAM CLI
if (-not (CommandExists "sam")) {
    Write-Output "Instalando AWS SAM CLI..."
    Invoke-WebRequest -Uri "https://github.com/aws/aws-sam-cli/releases/latest/download/AWS_SAM_CLI_64_PY3.msi" -OutFile "AWS_SAM_CLI.msi"
    Start-Process msiexec.exe -ArgumentList '/i AWS_SAM_CLI.msi /quiet' -Wait
    Remove-Item -Path "AWS_SAM_CLI.msi"
    Write-Output "AWS SAM CLI instalado."
} else {
    Write-Output "AWS SAM CLI já está instalado."
}

# Adicionando AWS SAM CLI ao Path
$samPath = "C:\Program Files\Amazon\AWSSAMCLI\bin"
if (-not ($env:Path -like "*$samPath*")) {
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$samPath", [System.EnvironmentVariableTarget]::Machine)
    Write-Output "AWS SAM CLI adicionado ao Path."
}

# Instalação do Serverless Framework
if (-not (CommandExists "serverless")) {
    Write-Output "Instalando Serverless Framework..."
    npm install -g serverless
    Write-Output "Serverless Framework instalado."
} else {
    Write-Output "Serverless Framework já está instalado."
}

Write-Output "Instalações e configurações concluídas."




#Executando o Script
#Abra o PowerShell como administrador.
#Navegue até o diretório onde o script foi salvo.
#Execute o script com o comando:

#.\install_dependencies.ps1

# aws --version
# node --version
# pulumi version
# python --version
# sam --version
# serverless --version
