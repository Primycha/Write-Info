# Write-Info
A PowerShell function created to simplify the logging of information. 
With Write-Info in your arsenal, information logging is fast and easy!

## Features
* Can write to console, log file and GUI at the same time
* Writes to log file by default in the current location
* Creates the log directory automatically (hidden) ("\Log\" and "\Log\Errors")
* Automatically attaches the $_.exception.message to the end of your error log
* Default text forecolor is yellow

## Examples

### Logging information to the default named log file, using positional parameter for the text
Write-Info "Operation was successfull!"

### Logging information to specified log file and adding some color
Write-Info -Text "Operation was successfull!" -LogName "ImportantTask" -TextColor Green

### Logging error message with the log name already specified with a variable
$LogName = "ImportantTask"

Write-Info "Operation failed!" -Error

## Blog post discussing this function on TechMeAway
https://techmeaway.net/2021/02/23/no-need-for-excuses-lets-get-logging/
