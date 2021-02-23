# Write-Info
A PowerShell function created to simplify the logging of information. 

Features:
* Can write to console, log file and GUI at the same time
* Writes to log file by default in the current location
* Creates the log directory automatically (hidden) ("\Log\" and "\Log\Errors")
* Automatically attaches the $_.exception.message to the end of your error log
