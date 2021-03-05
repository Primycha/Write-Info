<#
.Synopsis
Purpose of Write-info is to simplify the logging of information.
.DESCRIPTION
Write-Info simplifies the logging of information by writing to console, log files, error log files, status bar and rich text boxes.
It automatically adds exception messages to error messages.
Builds its own file structure for the log files.
.EXAMPLE
Write-Info "User $samaccountname has been added successfully to the group $group!" -TextColor "Green"
.EXAMPLE
Write-Info "Error when adding user $samaccountname to the group $group. " -Error
.EXAMPLE
Write-Info "User $samaccountname has been added successfully to the group $group!" -AsCMTrace
.INPUTS
Inputs to this cmdlet (if any)
.OUTPUTS
Output from this cmdlet (if any)
.NOTES
General notes
.FUNCTIONALITY
The functionality that best describes this cmdlet
#>

function Write-Info{
    [Cmdletbinding(DefaultParameterSetName = "Default")]
    param(
        [Alias("Status")] # Old parameter name
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Text
        ,
        [Parameter(Position=1)]
        [String]$LogName = $LogName
        ,
        [Alias("AsError")] # Old parameter name
        [Parameter(ParameterSetName = "Error")]
        [Switch]$Error
        ,
        [Parameter(ParameterSetName = "Warning")]
        [Switch]$Warning
        ,
        [Parameter(ParameterSetName = "AsCMTrace")]
        [Switch]$AsCMTrace
        ,
        [Alias("ForegroundColor")] # Helps with converting scripts from Write-Host to Write-Info
        [Validateset("Yellow","DarkYellow","Red","DarkRed","Cyan","DarkCyan","White","Green","DarkGreen","Gray","DarkGray","Blue","DarkBlue","Magenta","DarkMagenta","Black")]
        [String]$TextColor
        ,
        [Parameter(ParameterSetName = "OnlyToConsole")]
        [Switch]$OnlyToConsole
        ,
        [Parameter(ParameterSetName = "NoLogging")]
        [Switch]$NoLogging
        ,
        [Parameter(ParameterSetName = "OnlyLogging")]
        [Switch]$OnlyLogging
        ,
        [String]$Exception = $( if($_.exception.message){ $_.exception.message.replace("'",'') }else{ $null } )
        ,
        [Parameter(Mandatory = $false)]
        $AlsoWriteToRTB = $WriteInfoRichTextBoxObject # Add the Rich TextBox Object you want to write the text to or set the variable $WriteInfoRichTextBoxObject
        ,
        [Validateset("Black","Green","Yellow","Orange","Red","Blue")] # We can add more or even allow all in future but for now it is limited
        [Parameter(Mandatory = $false)]
        $RTBSelectionColor = "Black"
        ,
        [Switch]$ExcludeFromCurrentSessionLogs
        ,
        [Parameter(Mandatory = $false)]
        [String]$LogPath
        ,
        [Parameter(Mandatory = $false)]
        [String]$ErrorLogPath
    )

    ## Declare variables
    $Date = Get-Date -f "yyyy-MM-dd HH:mm:ss"
    $Computername = $env:COMPUTERNAME
    $Username = $env:USERNAME
    [int]$CMTraceType = 1

    # Categories
    if($Error){ $Category = "ERROR" }
    elseif($Warning){ $Category = "WARNING" }
    else{ $Category = "NORMAL" }

    # Booleans default values
    [Bool]$WriteToFile = $true
    [Bool]$WriteToConsole = $true
    [Bool]$WriteToGUI = $true

    # If name is empty, set a default value
    if([String]::IsNullOrWhiteSpace($LogName)){ $LogName = "General" }

    # Sets the default color of the text if no color has been selected
    if([String]::IsNullOrWhiteSpace($TextColor)){ $TextColor = "Yellow" }

    # If LogPath is not set, default to current location
    if(!$LogPath){

        $LogPath = "$(Get-Location|select -ExpandProperty path)\Log"

        # If the log folder doesn't exist, create it and set it as hidden
        if(!(Test-Path ".\Log")){ New-Item -Path ".\" -Name "Log" -ItemType "Directory"|%{ $_.Attributes="hidden" }}
    }

    # If ErrorLogPath is not set, default to LogPath location
    if(!$ErrorLogPath){

        $ErrorLogPath = "$LogPath\Errors"

        # If the error log folder doesn't exist, create it and set it as hidden
        if(!(Test-Path "$LogPath\Errors")){ New-Item -Path $LogPath -Name "Errors" -ItemType "Directory"|%{ $_.Attributes="hidden" }}
    }

    # This is changed below if the Error switch has been toggled
    # Use .log extension for cmtrace format otherwise use .txt
    if($AsCMTrace){ $ext = "log" }
    else { $ext = "txt" }
    $outputPath = "$LogPath\$LogName.$ext"
    Write-Verbose "OutputPath set to $outputPath"

    ## What actions will be taken based on switches used

    # Error
    if($Error){
        [Bool]$WriteToFile = $true
        [Bool]$WriteToConsole = $true
        [Bool]$WriteToGUI = $true
        [int]$CMTraceType = 3

        $RTBSelectionColor = "Red"

        # If we have an exception message and I have not already added it manually (which I did in old scripts), append the exception message to the text
        if((![string]::IsNullOrWhiteSpace($Exception)) -and ($Text -notlike "*Error message:*")){
            $Text = "$Text Error message: $Exception"
        }

        # Change the output path from the default
        
        # Use .log extension for cmtrace format otherwise use .txt
        if($AsCMTrace){ $ext = "log" }
        else { $ext = "txt" }
        $outputPath = "$errorLogPath\$LogName.$ext"
    }
    # Warning
    elseif($Warning){
        [Bool]$WriteToFile = $true
        [Bool]$WriteToConsole = $true
        [Bool]$WriteToGUI = $true
        [int]$CMTraceType = 2

        $RTBSelectionColor = "Orange"
    }
    # OnlyToConsole
    elseif($OnlyToConsole){
        [Bool]$WriteToFile = $false
        [Bool]$WriteToConsole = $true
        [Bool]$WriteToGUI = $false
    }
    # NoLogging
    elseif($NoLogging){
        [Bool]$WriteToFile = $false
        [Bool]$WriteToConsole = $true
        [Bool]$WriteToGUI = $true
    }
    # OnlyLogging
    elseif($OnlyLogging){
        [Bool]$WriteToFile = $true
        [Bool]$WriteToConsole = $false
        [Bool]$WriteToGUI = $false
    }

    # Write to log file
    if($WriteToFile){
        # Write in CMTrace format
        if($AsCMTrace){
            "<![LOG[$Text]LOG]!>" +`
            "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
            "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
            "component=`"$($MyInvocation.ScriptName)`" " +`
            "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
            "type=`"$Type`" " +`
            "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
            "file=`"`">"| Out-File -FilePath $outputPath -Append -Encoding default
        }
        # Write in regular format
        else
        {
            "[$Date][$Computername][$Username][$Category] $Text"| Out-File -FilePath $outputPath -Append -Encoding default
        }
    }

    # Write to Console
    if($WriteToConsole){
        if($Error){ Write-Host $Text -ForegroundColor Red }

        elseif($Warning){ Write-Warning $Text }

        else{ Write-Host $Text -ForegroundColor $TextColor }
    }

    # Write to GUI controls
    if($WriteToGUI){
        if($statusbar){
            $statusbar.Text = $Text
        }

        if($AlsoWriteToRTB){
            # Set the color for this message
            $AlsoWriteToRTB.SelectionColor = $RTBSelectionColor

            # Append the text
            $AlsoWriteToRTB.AppendText("`n$Text")

            # Reset the color to black. A possible future improvement would be to get the original color and then set it, but it will most likely be black.
            $AlsoWriteToRTB.SelectionColor = [Drawing.Color]::Black
        }
    }

    # Writes the log to a global variable which then can be called to show the current sessions logs.
    if(!$ExcludeFromCurrentSessionLogs){
        $CSLObj = New-Object psobject -Property @{
            Date = $Date
            Category = $Category
            Text = $Text
        }

        if($Global:CurrentSessionLogs){
            $Global:CurrentSessionLogs += $CSLObj
        }

        # Multithreaded applications
        elseif($Global:sync.CurrentSessionLogs){
            $Global:sync.CurrentSessionLogs += $CSLObj
        }
    }
}