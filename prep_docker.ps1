<#
.SYNOPSIS
    Downloads and installs Docker Desktop for Windows, configured for WSL2.
.DESCRIPTION
    This script performs the following actions:
    1. Checks for Administrator privileges.
    2. Downloads the latest Docker Desktop for Windows installer.
    3. Runs the installer silently with WSL2 backend enabled and license accepted.
.NOTES
    Run this script as Administrator.
    An internet connection is required to download the installer.
    The Docker Desktop download URL might need updating if Docker changes it.
#>

# --- Configuration ---
$DockerDesktopDownloadUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
$InstallerFileName = "DockerDesktopInstaller.exe"
$DownloadPath = "$env:TEMP\$InstallerFileName" # Download to the temporary directory

# --- Script Body ---

# 1. Check for Administrator Privileges
Write-Host "Checking for Administrator privileges..."
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Administrator privileges are required to run this script. Please re-run as Administrator."
    Read-Host "Press Enter to exit..."
    Exit 1
}
Write-Host "Administrator privileges confirmed." -ForegroundColor Green

# 2. Download Docker Desktop Installer
Write-Host "Downloading Docker Desktop installer from $DockerDesktopDownloadUrl..."
Write-Host "This may take a few minutes depending on your internet speed."
Try {
    Invoke-WebRequest -Uri $DockerDesktopDownloadUrl -OutFile $DownloadPath -ErrorAction Stop
    Write-Host "Docker Desktop installer downloaded successfully to $DownloadPath" -ForegroundColor Green
} Catch {
    Write-Error "Failed to download Docker Desktop installer. Error: $($_.Exception.Message)"
    Write-Error "Please check the download URL or your internet connection."
    Read-Host "Press Enter to exit..."
    Exit 1
}

# 3. Run Docker Desktop Installer Silently
Write-Host "Installing Docker Desktop... This may take some time and might require a reboot."
Write-Host "The installer will run silently. Please wait for this script to indicate completion or errors."
# Silent installation arguments:
# install: command to install
# --quiet: silent installation
# --accept-license: accepts the license agreement
# --backend=wsl-2: sets WSL 2 as the default backend
# --no-windows-containers: (Optional) if you only need Linux containers
$InstallerArgs = "install --quiet --accept-license --backend=wsl-2"
# $InstallerArgs = "install --quiet --accept-license --no-windows-containers --backend=wsl-2" # Alternative if you don't need Windows containers

Try {
    Start-Process -FilePath $DownloadPath -ArgumentList $InstallerArgs -Wait -Verb RunAs -ErrorAction Stop
    Write-Host "Docker Desktop installation process started. It may continue in the background or prompt for a reboot." -ForegroundColor Green
    Write-Host "If a reboot is not automatically prompted, it's recommended to reboot your system after installation."
} Catch {
    Write-Error "Failed to start Docker Desktop installation. Error: $($_.Exception.Message)"
    Write-Error "You might need to run the installer manually from $DownloadPath"
    Read-Host "Press Enter to exit..."
    Exit 1
}

# 4. Cleanup (Optional: remove the installer after use)
# Write-Host "Cleaning up installer..."
# Remove-Item -Path $DownloadPath -Force -ErrorAction SilentlyContinue

Write-Host "Docker Desktop installation script finished."
Write-Host "Please check your system for Docker Desktop and ensure it's running correctly."
Write-Host "You might need to log out and log back in, or reboot, for Docker Desktop to function fully."
Read-Host "Press Enter to exit..."

