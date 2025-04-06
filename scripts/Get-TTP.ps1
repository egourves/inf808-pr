# Read script arguments
param (
    [string]$outputToAFile = $false,
    [string]$outputFile = "TTPs.csv"
)

# Dictionary to match level names to their corresponding numbers
$levelDictionary = @{
    "low" = 1
    "medium" = 2
    "high" = 3
    "critical" = 4
}

# check if the output file already exists and ask for confirmation to overwrite
if ($outputToAFile -eq $true) {
    if (Test-Path $outputFile) {
        $overwrite = Read-Host "The file $outputFile already exists. Do you want to overwrite it? (Y/N)"
        if ($overwrite -ne 'Y') {
            Write-Host "Exiting script without overwriting the file." -ForegroundColor Yellow
            exit
        } else {
            Remove-Item $outputFile -Force
        }
    }
}

# Define the regex pattern for TTP numbers (TXXXX or TXXXX.XX)
$pattern = "T\d{4}(\.\d{3})?"
# Query events from the "Application" log for the "AuroraAgent" provider and format as XML
$Events = Get-WinEvent -LogName "Application" -FilterXPath "*[System[(Provider[@Name='AuroraAgent'])]]"

# Initialize variables for progress tracking
$totalEvents = $Events.Count
$i = 0

# Process each event
$Events | ForEach-Object {
    $rawXml = $_.ToXml()

    # Remove invalid XML characters from the string
    $cleanXml = $rawXml -replace "[^\u0009\u000A\u000D\u0020-\uD7FF\uE000-\uFFFD\u10000-\u10FFFF]", ""

    # Convert the cleaned string to an XmlDocument
    $xmlDocument = [xml]$cleanXml

    # Access the Event node
    $eventXml = $xmlDocument.Event
    $eventData = $eventXml.EventData.Data | Where-Object { $_ -like "Rule_References*" }

    # Check if the string matches a TTP number TXXX or TXXX.XX
    $eventData | ForEach-Object {
        if ($_ -match $pattern) {
            $output = [PSCustomObject]@{
                TTP = $matches[0]
                EventTime = $eventXml.System.TimeCreated.SystemTime
                Level = $levelDictionary[((($eventXml.EventData.Data | Where-Object { $_ -like "Rule_Level*" } | Select-Object -First 1) -split ':' | Select-Object -Last 1) -replace ' ', '')]
                ParentCommandLine = ($eventXml.EventData.Data | Where-Object { $_ -like "ParentCommandLine*" } | Select-Object -First 1) -split ':' | Select-Object -Last 1
                CommandLine = ($eventXml.EventData.Data | Where-Object { $_ -like "CommandLine*" } | Select-Object -First 1) -split ':' | Select-Object -Last 1
                EventID = $eventXml.System.EventID.'#text'
            }
            # Write the output to a file
            if($outputToAFile -eq $true) {
                 $output | Export-Csv -Path $outputFile -NoTypeInformation -Append
            } else {
                # Store the output in a variable for later use
                $output | Select-Object TTP, EventTime, Level, ParentCommandLine, CommandLine, EventID
            }
        }
    }

    # Display progress bar
    $i += 1
    Write-Progress -Activity "Searching Events" -Status "Progress:" -PercentComplete ($i / $totalEvents * 100) -CurrentOperation "Processing event $i of $totalEvents"
}

# Completion message
Write-Host "Processing complete." -ForegroundColor Green
if ($outputToAFile -eq $true) {
    Write-Host "Results saved to TTPs.csv" -ForegroundColor Green
} else {
    return $output
}