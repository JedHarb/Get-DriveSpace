# Get-DriveSpace
Remotely see total, free, and used drive space on all Windows machines, and warn about ones that are getting full.

You should probably manage your Windows machines with software like Windows Admin Center, but a simple script is a convenient way to check otherwise.

REQUIRED: This needs a basic edit to match your environment – the `-SearchBase` parameter should match the OU where you keep your servers. On that note, this script is geared towards servers, but there's no reason you couldn't edit the SearchBase to your computers OU.

You must have AD roles and permissions to pull machine names from AD. If you can't or don't want to use AD, but you know the names of the machines you want to check (and you have remote access to them), you could just remove the first few commands and set a variable equal to all the machines names, and replace `$RemainingADServers` with your variable.

Your typical disclaimer about running `Invoke-Command` applies here. Namely:
- The account running this script needs to have remote access to the machines.
- The remote machines need to allow Windows remote management (WinRM).
- The account running this script will cache a profile (if it doesn't already exist) onto the remote machine. You can change which account does this with `-credential`).

This is tested and working on Windows. I'm not sure about Linux or MacOS; I assume some changes would need to be made to `Invoke-Command` or `Get-PSDrive`.
