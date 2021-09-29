#Logs all events that take place in this powershell session and log them in C:\cabs\offboardinglog.log
Start-Transcript -append C:\cabs\offboardinglog.log

# Replace variables
$name = read-host "User First + Last name"
$name
$adname = @(Get-ADUser -Filter {name -like $name}| format-table samaccountname -HideTableHeaders)|out-string
#trim is important because there are spaces at the end of the variable...
$adname = $adname.Trim()
$termdate= Get-Date -Format "MM/dd/yyyy" 
$termdate
$email = @(Get-ADUser -Filter {name -like $name} -Properties mail |ft mail -HideTableHeaders) |out-string
$email
$fullname = $name
$password = read-host 'Off-boarding password'
$password
$delegate = read-host "First + last name of the email delegate"
$forwarddelegate = @(Get-ADUser -Filter {name -like $delegate} -Properties mail |ft mail -HideTableHeaders) |out-string
$forwarddelegate
$mailboxdelegate = $forwarddelegate
echo "Please confirm the settings are correct before continuing"
Pause

# Set logonhours to logon denied
# Representing the 168 hours in a week
$LH = New-Object 'Byte[]' 21

For ($k = 0; $k -le 20; $k = $k + 1)
{
    $LH[$k] = 0
} 
# Assign 21 byte array of all zeros to the logonHours attribute of the user.            
Set-ADUser $adname -Replace @{logonHours=$LH}


# Disables account and resets password 
Disable-ADAccount -identity $adname
Set-adaccountpassword -identity $adname -reset -NewPassword (ConvertTo-SecureString -AsPlainText "$password" -Force)


# Sets the Term date description and extension attribute
Set-ADUser $adname -Description "TERM DATE $termdate"
Set-ADUser $adname -Add @{extensionAttribute1 = "TERM DATE $termdate"}


# Sets the MsExchHideFromAddressLists to true
Set-ADUser $adname -Add @{MsExchHideFromAddressLists = ($persistent -ne $false)}


# Removes the ad user from all groups
Get-ADUser -Identity $adname -Properties MemberOf | ForEach-Object {
  $_.MemberOf | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false}
  
# Adds user to awarenesstraining exclude group
Add-ADGroupMember -Identity knowbe4_exclude -Members $adname

# Disables 365 sign on 
Connect-AzureAD
Set-AzureADUser -ObjectID $email -AccountEnabled $false

# Connect Exchange online
Connect-ExchangeOnline

# Disable OWA and Activesync
Set-CASMailbox -Identity "$fullname" -OWAEnabled $false
Set-CASMailbox -Identity "$fullname" -ActiveSyncEnabled $false

#Sets the full mailbox permissions and forwarding rule
Set-Mailbox -Identity "$fullname" -ForwardingAddress "$forwarddelegate"
Add-MailboxPermission -Identity "$fullname" -User "$mailboxdelegate" -AccessRights FullAccess -InheritanceType All

Stop-transcript

Pause



