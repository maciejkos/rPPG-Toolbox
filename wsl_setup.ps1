<#
.SYNOPSIS
    Sets up WSL2 and installs a specified Ubuntu distribution.
.DESCRIPTION
    This script performs the following actions:
    1. Checks for Administrator privileges.
    2. Enables "Windows Subsystem for Linux" and "Virtual Machine Platform" if not already enabled.
    3. Installs a specified Ubuntu distribution via WSL (e.g., Ubuntu-24.04 LTS).
    4. Updates the WSL kernel.
    5. Ensures the distribution is set to WSL version 2.
    6. Optionally sets the new distribution as the default.
    A system reboot may be required after enabling Windows features if they were not previously enabled.
.NOTES
    Run this script as Administrator.
#>
Set-ExecutionPolicy Bypass -Scope Process -Force
# --- Configuration ---
$DistroName = "Ubuntu-22.04" # Specify the Ubuntu distribution name from `wsl --list --online`
                             # Common options: "Ubuntu", "Ubuntu-24.04", "Ubuntu-22.04", "Ubuntu-20.04"
$SetAsDefault = $true        # Set to $true to make this distro the default, $false otherwise

# --- Script Body ---

# 1. Check for Administrator Privileges
Write-Host "Checking for Administrator privileges..."
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Administrator privileges are required to run this script. Please re-run as Administrator."
    Read-Host "Press Enter to exit..."
    Exit 1
}
Write-Host "Administrator privileges confirmed." -ForegroundColor Green

# 2. Enable WSL and Virtual Machine Platform features if not already enabled.
#    The `wsl --install` command should handle this on modern Windows systems.
#    However, we can explicitly check and enable for robustness or older systems if needed.

Write-Host "Ensuring Windows Subsystem for Linux and Virtual Machine Platform features are enabled..."

$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
$vmPlatformFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

If ($wslFeature.State -ne "Enabled") {
    Write-Host "Enabling Windows Subsystem for Linux feature..."
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    Write-Host "Windows Subsystem for Linux feature enabled." -ForegroundColor Green
    $RebootRequired = $true
} Else {
    Write-Host "Windows Subsystem for Linux feature is already enabled."
}

If ($vmPlatformFeature.State -ne "Enabled") {
    Write-Host "Enabling Virtual Machine Platform feature..."
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    Write-Host "Virtual Machine Platform feature enabled." -ForegroundColor Green
    $RebootRequired = $true
} Else {
    Write-Host "Virtual Machine Platform feature is already enabled."
}

If ($RebootRequired) {
    Write-Warning "One or more Windows features were enabled. A system reboot is likely required for changes to take full effect."
    Write-Warning "Please reboot your system and then re-run this script if the Ubuntu installation step fails, or proceed if confident."
    Read-Host "Press Enter to continue with the script, or Ctrl+C to exit and reboot manually..."
}

# 3. Update WSL Kernel (good practice, especially after enabling features or first install)
Write-Host "Updating WSL kernel..."
wsl --update
If ($LASTEXITCODE -ne 0) {
    Write-Warning "WSL kernel update might have failed or reported an issue. Continuing..."
} Else {
    Write-Host "WSL kernel updated (or was already up-to-date)." -ForegroundColor Green
}

# Set WSL 2 as the default version for new installations
Write-Host "Setting WSL 2 as the default version for future new distributions..."
wsl --set-default-version 2
If ($LASTEXITCODE -ne 0) {
    Write-Warning "Could not set WSL 2 as the default version. This might occur if WSL is not fully installed/enabled or if it's already the default."
} Else {
    Write-Host "WSL 2 is now the default version for new distributions." -ForegroundColor Green
}

# 4. Install the specified Ubuntu Distribution if not already installed
Write-Host "Checking if '$DistroName' is already installed..."
$installedDistros = wsl --list --quiet
If ($installedDistros -match [regex]::Escape($DistroName)) {
    Write-Host "'$DistroName' is already installed." -ForegroundColor Yellow
} Else {
    Write-Host "'$DistroName' not found. Attempting to install..."
    # List available distributions to ensure the name is valid (optional, good for user feedback)
    Write-Host "Available online distributions (partial list):"
    wsl --list --online | Select-String -Pattern "Ubuntu" | Select-Object -First 5 # Show some Ubuntu options

    Write-Host "Installing '$DistroName'... This may take some time."
    wsl --install -d $DistroName --no-launch
    If ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install '$DistroName'. Please check the distribution name and ensure WSL features are fully enabled (a reboot might be needed)."
        Read-Host "Press Enter to exit..."
        Exit 1
    }
    Write-Host "'$DistroName' installed successfully." -ForegroundColor Green
}

# 5. Ensure the distribution is set to WSL version 2
Write-Host "Setting '$DistroName' to use WSL version 2..."
wsl --set-version $DistroName 2
If ($LASTEXITCODE -ne 0) {
    Write-Warning "Could not set '$DistroName' to WSL 2. It might already be WSL 2, or an error occurred."
} Else {
    Write-Host "'$DistroName' is now set to use WSL version 2." -ForegroundColor Green
}

# 6. Optionally, set the new distribution as the default
If ($SetAsDefault) {
    Write-Host "Setting '$DistroName' as the default WSL distribution..."
    wsl --set-default $DistroName
    If ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not set '$DistroName' as the default distribution."
    } Else {
        Write-Host "'$DistroName' is now the default WSL distribution." -ForegroundColor Green
    }
}

Write-Host "WSL2 and Ubuntu distribution setup script completed."
Write-Host "You may need to launch '$DistroName' once manually from the Start Menu or `wsl -d $DistroName` "
Write-Host "to complete its initial first-time setup (creating user, password, etc.) if it's a brand new installation."
Read-Host "Press Enter to exit..."