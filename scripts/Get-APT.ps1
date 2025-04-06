.\Get-TTP.ps1 | Group-Object -Property TPP | ForEach-Object {     [PSCustomObject]@{
         TTP = $_.Name  # Reuse the category from the original objects
         Count = $_.Count
         EventDetail = $_.Group  # Retain the original objects in the group
     }} | Sort-Object -Property Count | .\Match-TTP-APT.ps1