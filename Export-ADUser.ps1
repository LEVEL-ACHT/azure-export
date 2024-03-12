# Config for customer name and user
$CustomerName = "Name of the customer"
$applicationId = "Application ID of the customer"
$tenantId = "Tenant ID of the customer"

# Config send mail
$EmailTo = "<Mail address of the LEVEL 8 employee"
$BotUser = "<Mail address of the bot"
$BotPassword = "<Application password of the bot user>"
$SMTPServer = "smtp.gmail.com"

# Check if the directory path ends with a backslash
if ($DIR -match '.+?\\$') {
    # If it does, remove the backslash
    $DIR = $DIR.Substring(0, $DIR.Length-1)
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

# Get all Azure Active Directory groups
$allgroups = Get-AzADGroup

$result = foreach ( $group in $allgroups ) {

    # Initialize a hashtable to store group and member details
    $hash = @{
        GroupName=$group.DisplayName
        Member=''
        Email=''
        UserPrincipalName=''
        ObjectId=''
    }
   
    $groupid = $group.id
    $groupdisplayname = $group.DisplayName

        if ( $members = Get-AzADGroupMember -GroupObjectId $groupid ) {

            foreach ( $member in $members ) {

                 # Check if the member is a user
                if ( $member.OdataType -eq '#microsoft.graph.user' ) {

                    $objectid = $member.Id
                    $userinfo = Get-AzADUser -ObjectId $objectid
                    $displayname = $userinfo.DisplayName
                    $email = $userinfo.Mail
                    $upn = $userinfo.UserPrincipalName
                     
                    $hash.Member = $displayname
                    $hash.Email = $email
                    $hash.UserPrincipalName = $upn
                    $hash.ObjectId = $objectid
                    New-Object psObject -Property $hash
                }

                # Check if the member is a nested group
                elseif ( $member.OdataType -eq '#microsoft.graph.group' ) {

                    $objectid = $member.Id
                    $userinfo = Get-AzADGroup -ObjectId $objectid
                    $displayname = $userinfo.DisplayName
                    $email = $userinfo.Mail
                    $upn = 'No UPN - Nested Group'
                     
                    $hash.Member = $displayname
                    $hash.Email = $email
                    $hash.UserPrincipalName = $upn
                    $hash.ObjectId = $objectid
                    New-Object psObject -Property $hash                
                }
                
                # Check if the member is a contact
                elseif ( $member.OdataType -eq '#microsoft.graph.orgContact' ) {

                    $objectid = $member.Id
                    $userinfo = Get-AzureADContact -ObjectId $objectid
                    $displayname = $userinfo.DisplayName
                    $email = $userinfo.Mail
                    $upn = 'No UPN - Contact'
                     
                    $hash.Member = $displayname
                    $hash.Email = $email
                    $hash.UserPrincipalName = $upn
                    $hash.ObjectId = $objectid
                    New-Object psObject -Property $hash
                }

                # Check if the member is a device
                elseif ( $member.OdataType -eq '#microsoft.graph.device' ) {

                    $objectid = $member.Id
                    $userinfo = Get-AzureADDevice -ObjectId $objectid
                    $displayname = $userinfo.DisplayName
                    $email = 'No Email - Device'
                    $upn = 'No UPN - Device'
                     
                    $hash.Member = $displayname
                    $hash.Email = $email
                    $hash.UserPrincipalName = $upn
                    $hash.ObjectId = $objectid
                    New-Object psObject -Property $hash
               
                }

                else {
                    $objectid = $member.Id
                    $displayname = 'Unknown object'
                    $email = 'Unknown object'
                    $upn = 'Unknown object'
                     
                    $hash.Member = $displayname
                    $hash.Email = $email
                    $hash.UserPrincipalName = $upn
                    $hash.ObjectId = $objectid
                    New-Object psObject -Property $hash

                }
            }
        }

         # If the group has no members, update the hashtable accordingly
        else {
           $hash.Member = 'No members'
           $hash.Email = ''
           $hash.UserPrincipalName = ''
           $hash.ObjectId = ''
           New-Object psObject -Property $hash

        }
}

# Export the results to a CSV file in the Documents folder
$LogDate = Get-Date -f dd.MM-hh_mm

# Ensure the Level8 directory exists
$UserExportLogPath = Join-Path -Path $DIR -ChildPath "user-export-log"
if (-not (Test-Path -Path $UserExportLogPath)) {
    New-Item -ItemType Directory -Path $UserExportLogPath | Out-Null
}

# Export the results
$FileName = "ad_" + $CustomerName +  "_" + $LogDate
$result | Export-Csv -Path (Join-Path -Path $UserExportLogPath -ChildPath "$FileName.csv") -NoTypeInformation -Encoding UTF8

#Sending gmail
$BotPasswordSecureString = ConvertTo-SecureString -String $BotPassword -AsPlainText -Force
$cred=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $BotUser, $BotPasswordSecureString 
$Subject = "DailyExport " + $CustomerName + " " +$LogDate
$Body = "Anbei der Export vom "+$LogDate
$filenameAndPath = Join-Path -Path $UserExportLogPath -ChildPath "$FileName.csv"
$SMTPMessage = New-Object System.Net.Mail.MailMessage($BotUser,$EmailTo,$Subject,$Body)
$attachment = New-Object System.Net.Mail.Attachment($filenameAndPath)
$SMTPMessage.Attachments.Add($attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SMTPServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($cred.UserName, $cred.Password);
$SMTPClient.Send($SMTPMessage)

# Pause the script for 5 seconds
Start-Sleep -Seconds 5