Set-PSDebug -Trace 1
Import-Module WebAdministration
Set-ItemProperty -Path IIS:\AppPools\".Net v4.5" -Name enable32BitAppOnWin64 -Value "True"
Remove-WebSite -Name 'Default Web Site'