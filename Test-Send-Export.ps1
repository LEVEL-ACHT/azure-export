# Define the parameters
$CustomerName = "Name of the customer"
$LogDate = Get-Date -Format "yyyy-MM-dd"
$EmailTo = "<Mail address of the LEVEL8 export mail box>"
$BotUserMail = "<Mail address of the bot>"
$BotPassword = "<Application password of the bot user>"
$SMTPServer = "smtp.gmail.com"

# Create the SecureString password
$BotPasswordSecureString = ConvertTo-SecureString -String $BotPassword -AsPlainText -Force

# Create the PSCredential object
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $BotUserMail, $BotPasswordSecureString 

# Create the subject and body of the email
$Subject = "Test-Export " + $CustomerName + " " + $LogDate
$Body = "This is a test export to check if the export works "+$LogDate

# Create the MailMessage object
$SMTPMessage = New-Object System.Net.Mail.MailMessage($BotUserMail,$EmailTo,$Subject,$Body)

# Create the SmtpClient object
$SMTPClient = New-Object Net.Mail.SmtpClient($SMTPServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($cred.UserName, $cred.Password)

# Try to send the email
try {
    $SMTPClient.Send($SMTPMessage)
    Write-Host "Email sent successfully."
} catch {
    Write-Host "Failed to send email: $_"
}