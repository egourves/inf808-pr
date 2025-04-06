# Read script arguments (output file)
param (
    [string]$outputFile = "TTPs.csv"
)

# Check if the output file already exists and ask for confirmation to overwrite
if (Test-Path $outputFile) {
    $overwrite = Read-Host "The file $outputFile already exists. Do you want to overwrite it? (Y/N)"
    if ($overwrite -ne 'Y') {
        Write-Host "Exiting script without overwriting the file." -ForegroundColor Yellow
        exit
    } else {
        Remove-Item $outputFile -Force
    }
}

# Query events from the "Application" log for the "AuroraAgent" provider and format as XML
$pattern = "T\d{4}"
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
                TPP = $matches[0]
                EventTime = $eventXml.System.TimeCreated.SystemTime
                EventID = $eventXml.System.EventID.'#text'
                RecordID = $eventXml.System.EventRecordID
            }
            # Write the output to a file
            $output | Export-Csv -Path $outputFile -NoTypeInformation -Append
        }
    }

    # Display progress bar
    $i += 1
    Write-Progress -Activity "Searching Events" -Status "Progress:" -PercentComplete ($i / $totalEvents * 100) -CurrentOperation "Processing event $i of $totalEvents"
}

# Completion message
Write-Host "Processing complete." -ForegroundColor Green
Write-Host "Results saved to TTPs.csv" -ForegroundColor Green
