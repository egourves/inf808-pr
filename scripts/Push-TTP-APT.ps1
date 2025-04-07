$body = .\Get-TTP.ps1 | Group-Object -Property TPP | ForEach-Object {     [PSCustomObject]@{
    TTP = $_.Name  # Reuse the category from the original objects
    Count = $_.Count
    EventDetail = $_.Group  # Retain the original objects in the group
}} | Sort-Object -Property Count | .\Match_APT_with_TTP | Out-String
$params = @{
To = 'NetworkAdmin@inf808.com'
From = 'no-reply-psh@inf808.com'
Subject = 'APT link Report'
Body = $body
SmtpServer = 'smtp.inf808.com'
}
Send-MailMessage @params