# This script tests whether the password has been stored correctly and whether a login can be carried out successfully

# Config for customer name and user
$applicationId = "<Application ID of the customer>"
$tenantId = "<Tenant ID of the customer>"

# Setup DIR using the current file's directory 
$DIR = $PSScriptRoot

# Check if the directory path ends with a backslash
if ($DIR -match '.+?\\$') {
    # If it does, remove the backslash
    $DIR = $DIR.Substring(0, $DIR.Length - 1)
}

# Check if the password file exists in the directory
if (Test-Path -Path "$DIR\password.txt") {
    
    # If it does, get the secure password from the file
    $applicationSecretText = Get-Content "$DIR\password.txt"
    $applicationSecret = $applicationSecretText | ConvertTo-SecureString

    # Create a new PSCredential object with the username and secure password
    $credential = New-Object System.Management.Automation.PSCredential -ArgumentList $applicationId, $applicationSecret
    Write-Host "password.txt file has been entered and the login is executed with the stored password."
    
    Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantId
}