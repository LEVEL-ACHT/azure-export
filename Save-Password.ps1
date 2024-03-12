param(
    [string]$DIR
)

if (!$DIR) {
    $DIR = [string](Get-Location)
}

if ($DIR -match '.+?\\$') {
    $DIR = $DIR.Substring(0, $DIR.Length-1)
}

# Inform the user about the need to enter a password or application password
Write-Host "Please refer to the README for instructions on how to generate an application password."
Write-Host "Please enter the password or application password (if MFA is activated) for the user account:"
$password = Read-Host -AsSecureString

# Check if the user has entered a password/ application secret
if ($password.Length -eq 0) {
    Write-Host "You must enter a password. Please try again."
    return
}

$secureStringText = $password | ConvertFrom-SecureString
Set-Content "$DIR\password.txt" $secureStringText