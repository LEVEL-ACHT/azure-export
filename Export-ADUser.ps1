# Config for customer name and user
$CustomerName = "<Name of the customer>"
$applicationId = "<Application ID of the customer>"
$tenantId = "<Tenant ID of the customer>"

# Config send mail
$EmailTo = "<Mail address of the LEVEL8 export mail box>"
$BotUserMail = "<Mail address of the bot>"
$BotPassword = "<Application password of the bot user>"
$SMTPServer = "smtp.gmail.com"

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

# Retrieve all Azure AD users
$allUsers = Get-AzADUser 

# Filter out guest accounts
$filteredUsers = $allUsers | Where-Object { $_.UserType -ne 'Guest' }

# Export the results to a CSV file
$LogDate = Get-Date -f dd.MM-hh_mm

# Ensure the LEVEL8 directory exists
$UserExportLogPath = Join-Path -Path $DIR -ChildPath "user-export-log"
if (-not (Test-Path -Path $UserExportLogPath)) {
    New-Item -ItemType Directory -Path $UserExportLogPath | Out-Null
}

# Export the results
$FileName = "ad_" + $CustomerName + "_" + $LogDate

# Output user details
$filteredUsers | ForEach-Object {
    [PSCustomObject]@{
        DisplayName       = $_.DisplayName
        Email             = $_.Mail
        UserPrincipalName = $_.UserPrincipalName
        ObjectId          = $_.Id
    }
} | Export-Csv -Path (Join-Path -Path $UserExportLogPath -ChildPath "$FileName.csv") -NoTypeInformation -Encoding UTF8

#Sending mail
$BotPasswordSecureString = ConvertTo-SecureString -String $BotPassword -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $BotUserMail, $BotPasswordSecureString 
$Subject = "DailyExport " + $CustomerName + " " + $LogDate
$Body = "Anbei der Export vom " + $LogDate
$filenameAndPath = Join-Path -Path $UserExportLogPath -ChildPath "$FileName.csv"
$SMTPMessage = New-Object System.Net.Mail.MailMessage($BotUserMail, $EmailTo, $Subject, $Body)
$attachment = New-Object System.Net.Mail.Attachment($filenameAndPath)
$SMTPMessage.Attachments.Add($attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SMTPServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($cred.UserName, $cred.Password);
$SMTPClient.Send($SMTPMessage)

# Pause the script for 5 seconds
Start-Sleep -Seconds 5