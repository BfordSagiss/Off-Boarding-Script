Start-Transcript -append C:\cabs\offboardinglog.log

# Replace variables


$adname=read-host "AD Username"
$termdate=read-host "Write 'Term Date mm/dd/yyyy"
$email=read-host "Off-boarded user email"
$fullname=read-host "Off-boarded user First + Last name"
$password=read-host 'Off-boarding password'
$forwarddelegate=read-host "Insert the email of the user who will have emails forwarded to them"
$mailboxdelegate=read-host "Insert the first and last name of the user who will recieve full mailbox access"


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
Set-ADUser $adname -Description "$termdate"
Set-ADUser $adname -Add @{extensionAttribute1 = "$termdate"}


# Sets the MsExchHideFromAddressLists to true
Set-ADUser $adname -Add @{MsExchHideFromAddressLists = ($persistent -ne $false)}


# Removes the ad user from all groups
Get-ADUser -Identity $adname -Properties MemberOf | ForEach-Object {
  $_.MemberOf | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false}
  # Adds user to awarenesstraining exclude group
Add-ADGroupMember -Identity awarenesstrainingexclude -Members $adname
Pause


# Disable AAD sign on and 365
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

