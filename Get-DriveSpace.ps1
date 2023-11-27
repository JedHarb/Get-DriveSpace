# Get the names of all your servers (you must have AD roles and permissions).
$ADServers = 
	(Get-ADComputer -Filter 'Enabled -eq $True' -SearchBase "OU=CompanyServers,DC=MyDomain,DC=com").name +	# <---- EDIT THIS
	(Get-ADComputer -Filter 'Enabled -eq $True' -SearchBase "OU=CompanyServers2,DC=MyDomain,DC=com").name | # <---- In case you have multiple OUs with machines to check, otherwise you can remove this.
	Sort-Object
	
# To exclude a server from the report, add it to this list. So edit this as needed (it won't hurt anything to leave these examples, they'll get filtered out in the next command).
$ExcludedServersList = 'OldServer1','UnusedServer2' | Sort-Object

# Reduced the list to only excluded servers that actually still exist in AD (in case the above list gets outdated).
$ExcludedServersInAD = (Compare-Object $ADServers $ExcludedServersList -ExcludeDifferent -IncludeEqual).InputObject

# Get the rest of the AD servers we want to check.
$RemainingADServers = (Compare-Object $ADServers $ExcludedServersInAD | Where-Object SideIndicator -eq "<=").InputObject

$Results = $RemainingADServers | ForEach-Object {
	if (Test-Connection -BufferSize 32 -Count 1 -ComputerName $_ -Quiet) {
		Invoke-Command -ComputerName $_ -ScriptBlock {
			Get-PSDrive | Where-Object {($_.DisplayRoot -eq $null -and $_.Used -gt 0)} | ForEach-Object { # Only local drives that have data (no network drives, registries, aliases, certificates, empty disk drives, etc.)
				$Total = $_.Used + $_.Free
				$PercentUsed = $_.Used / $Total * 100
				$Warning = if ($PercentUsed -gt 85) {" <---Warning"} # Feel free to change this number. What percentage full does a drive need to be in order to be tagged with "Warning"?
				"$env:COMPUTERNAME $($_.Root)"
				" Percentage used: "+[math]::Round($PercentUsed,2)+$Warning
				" Total: "+[math]::Round($Total/1GB,2)+" GB"
				" Used: "+[math]::Round($_.Used/1GB,2)+" GB"
				" Free: "+[math]::Round($_.Free/1GB,2)+" GB"
				""
			}
		} -ErrorAction SilentlyContinue -ErrorVariable NoRemote
		if ($NoRemote) {
			"Error: $_ is online, but I'm unable to retrieve drives remotely. Remote commands may be disabled.`n"
		}
	}
	else {
		"Error: Can't ping $_. Is it offline?`n"
	}
}

$OFS = "`r`n" # Preserve newlines when an array is expressed as a string.

$Warnings = if ($Results | Select-String "Warning") {
	"Warnings - Drives over 85% full:`n`n" + (($Results | Select-String "Warning" -Context 1,0) -replace ' <---Warning',"`n" -replace '  ',' ' -replace '>') + "`n`n"
}

$Errors = if ($Results | Select-String "Error") {
	"Errors - Servers offline or drives that can't be remotely polled:`n`n" + (($Results -like "Error*") -replace 'Error:' -replace '\n') + "`n`n`n"
}

$ExcludedServersReport = if ($ExcludedServersInAD) {
	"`nServers excluded from checking:`n" + $ExcludedServersInAD
}

$FinalReport = $Warnings + $Errors + $Results + $ExcludedServersReport
# Do whatever you want with FinalReport at this point.
# For example, if the machine running this script has Outlook, you could use Send-MailMessage to email you the report (and you may have to whitelist the -From address).
Send-MailMessage -To youremail@yourdomain.com -From ServerDrives@MyPowershellScript -Subject "Report - All Server Drive Usage" -Body ($FinalReport | Out-String) -port 25 -SmtpServer 'mailserver.yourdomain.com' # <---- EDIT THIS
