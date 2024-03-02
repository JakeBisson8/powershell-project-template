[cmdletbinding()]
param(
    [string[]] $Includes,
    [string[]] $Excludes,
    [string] $IgnoreFilePath = './.psscriptanalyzerignore',
    [string] $Directory = '.',
    [string] $SettingsFilePath = './PSScriptAnalyzerSettings.psd1',
    [switch] $Fix
)

<#
    .DESCRIPTION
        Runs the analyzer against specified files and returns the exit code and error counts

    .PARAMETER Files
        List of file names to be analyzed

    .PARAMETER Fix
        Defines if fixable errors should be automatically fixed or not. This defines if -Fix should be included when calling Invoke-ScriptAnalyzer

    .PARAMETER Settings
        The settings to use when analyzing. This is passed to the -Settings parameter of Invoke-ScriptAnalyzer

    .OUTPUTS
        A hashtable with properties ExitCode and ErrorCounts where exit code is an int and ErrorCounts is a hashtable with properties Error, Warning, and Information containing the total counts of those errors for this run
#>
Function Run-Analyzer {
    [cmdletbinding()]
    [OutputType([System.Collections.HashTable])]
    param(
        [string[]] $Files = @(),
        [boolean] $Fix = $False,
        [System.Collections.Hashtable] $Settings
    )

    $ExitCode = 0
    $TotalErrorCounts = @{
        Error       = 0
        Warning     = 0
        Information = 0
    }
    foreach ($File in $Files) {
        Write-Host "`n$($File -replace [regex]::Escape((Resolve-Path -Path $Directory)), '.')" -ForegroundColor Cyan
        try {
            if ($Fix -and $Settings) {
                $Errors = Invoke-ScriptAnalyzer -Path $File -Recurse -ErrorAction Stop -Fix -Settings $Settings
            } elseif ($Fix) {
                $Errors = Invoke-ScriptAnalyzer -Path $File -Recurse -ErrorAction Stop -Fix
            } elseif ($Settings) {
                $Errors = Invoke-ScriptAnalyzer -Path $File -Recurse -ErrorAction Stop -Settings $Settings
            } else {
                $Errors = Invoke-ScriptAnalyzer -Path $File -Recurse -ErrorAction Stop
            }
            if ($Errors) {
                # Report the error details in a table
                $Errors | Format-Table -AutoSize | Out-Host

                # Update error counts and report count summary for the current file
                $ErrorCounts = @{
                    Error       = ($Errors | Where-Object { $_.Severity -like 'Error' }).Count
                    Warning     = ($Errors | Where-Object { $_.Severity -like 'Warning' }).Count
                    Information = ($Errors | Where-Object { $_.Severity -like 'Information' }).Count
                }
                Write-Host "File Summary (Error: $($ErrorCounts.Error), Warning: $($ErrorCounts.Warning), Informtion $($ErrorCounts.Information))" -ForegroundColor DarkYellow
                $TotalErrorCounts.Error += $ErrorCounts.Error
                $TotalErrorCounts.Warning += $ErrorCounts.Warning
                $TotalErrorCounts.Information += $ErrorCounts.Information

                $ExitCode = 1
            } else {
                Write-Host 'No errors to report' -ForegroundColor Green
            }
        } catch {
            Write-Host "Error when analysing: $_" -ForegroundColor Red
            $ExitCode = 1
        }
    }
    return @{ ExitCode = $ExitCode ; ErrorCounts = $TotalErrorCounts }
}

<#
    .DESCRIPTION
        Given a directory returns a list of files based on given filter settings

    .PARAMETER Directory
        The starting directory to filter from

    .PARAMETER Includes
        The file patterns to be included in the filtered set

    .PARAMETER Excludes
        The file patterns to be excluded from the filtered set

    .OUTPUTS
        List of strings containing file names representing the filtered set of files
#>
Function Filter-Files {
    [cmdletbinding()]
    [OutputType([System.Object[]])]
    param(
        [string] $Directory = '.',
        [string[]] $Includes,
        [string[]] $Excludes
    )

    if ($Null -ne $Includes -and $Includes.count -eq 0) {
        return @()
    }

    $Files = (Get-ChildItem -Path $Directory -Recurse -File -Include @('*.ps1', '*.psm1', '*.psd1')).FullName

    $FilteredFiles = $Files | Where-Object {
        $Include = $true
        foreach ($IncludeCondition in $Includes) {
            if (($_ -replace '\\', '/') -like "*$($IncludeCondition -replace '\\', '/')*") {
                $Include = $true
                break
            } elseif (($_ -replace '/', '\\') -like "*$($IncludeCondition -replace '/', '\\')*") {
                $Include = $true
                break
            }
            $Include = $false
        }

        $Exclude = $false
        foreach ($ExcludeCondition in $Excludes) {
            if (($_ -replace '\\', '/') -like "*$($ExcludeCondition -replace '\\','/')*") {
                $Exclude = $true
                break
            } elseif (($_ -replace '/', '\\') -like "*$($ExcludeCondition -replace '/','\\')*") {
                $Exclude = $true
                break
            }
        }
        return $Include -and -not $Exclude
    }
    return $FilteredFiles
}

# Main
Write-Host "`nStarting Script Analyzer" -ForegroundColor Green

# Validate the directory exists
try {
    Resolve-Path -Path $Directory | Out-Null
} catch {
    Write-Host "`nUnable to resolve path: $Directory" -ForegroundColor Red
    Exit 1
}

# Load analyzer settings for this run
try {
    $Settings = Import-PowerShellDataFile -Path $SettingsFilePath -ErrorAction Stop
    Write-Host "Using settings found in $SettingsFilePath" -ForegroundColor Magenta
} catch {
    Write-Host "Failed to import settings from $SettingsFilePath, using default settings" -ForegroundColor Magenta
}

if ($Fix) {
    Write-Host "Using fix parameter. Fixable errors will be fixed" -ForegroundColor Magenta
} else {
    Write-Host "Not using fix parameter. No errors will be fixed" -ForegroundColor Magenta
}

# Combine the excludes conditions from the $Excludes parameter and the ignore file if one is present
$CombinedExcludes = $Excludes
if (Resolve-Path -Path $IgnoreFilePath) {
    $CombinedExcludes += (Get-Content -Path $IgnoreFilePath)
}

$FilteredFiles = Filter-Files -Directory $Directory -Includes $Includes -Excludes $CombinedExcludes

# Run the analyzer
$ExitCode = 0
if ($FilteredFiles) {
    Write-Host "`nRunning analyzer against $($FilteredFiles.Count) file(s) in $Directory" -ForegroundColor Green
    $Results = Run-Analyzer -Files $FilteredFiles -Fix $Fix -Settings $Settings
    Write-Host "`nAnalysis completed on $($FilteredFiles.Count) file(s) in $Directory" -ForegroundColor Green
    Write-Host "Analysis report (Error: $($Results.ErrorCounts.Error), Warning: $($Results.ErrorCounts.Warning), Information: $($Results.ErrorCounts.Information))" -ForegroundColor DarkYellow
    $ExitCode = $Results.ExitCode
} else {
    Write-Host "`nNo files were identified for analysis" -ForegroundColor DarkYellow
}

Write-Host "`nExiting with code $ExitCode`n" -ForegroundColor Magenta
Exit $ExitCode