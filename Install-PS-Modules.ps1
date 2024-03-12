# Set the execution policy to allow scripts to run
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Define a function to check and install a module
function CheckAndInstallModule {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleName
    )

    # Check if the module is already installed
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        # If the module is not installed, install it
        Install-Module -Name $ModuleName -Force
    } else {
        Write-Output "Module '$ModuleName' is already installed."
    }
}

# Use the function to check and install the 'Az' and 'AzureAD' modules
CheckAndInstallModule -ModuleName 'Az'
CheckAndInstallModule -ModuleName 'AzureAD'
