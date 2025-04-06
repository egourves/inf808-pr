if ($outputToAFile -ne $true -and $output) {
    Write-Host "[+] Analyse des TTP extraits avec MITRE ATT&CK..." -ForegroundColor Cyan

    # Extraire les TTP uniques
    $myTTPs = $output | ForEach-Object { $_.TPP.Trim() } | Sort-Object -Unique

    # Télécharger la base ATT&CK
    $attackJsonUrl = "https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json"
    try {
        Write-Host "[*] Téléchargement de la base ATT&CK..."
        $attackData = Invoke-RestMethod -Uri $attackJsonUrl
    } catch {
        Write-Host "[-] Erreur de téléchargement du JSON ATT&CK." -ForegroundColor Red
        return
    }

    # Extraire les groupes et leurs TTP
    $groupNames = @{}
    $groupTTPs = @{}

    foreach ($obj in $attackData.objects) {
        if ($obj.type -eq "intrusion-set") {
            $groupNames[$obj.id] = $obj.name
            $groupTTPs[$obj.name] = @()
        }
    }

    foreach ($rel in $attackData.objects | Where-Object { $_.type -eq "relationship" -and $_.relationship_type -eq "uses" }) {
        $groupName = $groupNames[$rel.source_ref]
        if ($groupName) {
            $ttpObj = $attackData.objects | Where-Object { $_.id -eq $rel.target_ref -and $_.type -eq "attack-pattern" } | Select-Object -First 1
            $ttpId = $ttpObj?.external_references | Where-Object { $_.source_name -eq "mitre-attack" } | Select-Object -ExpandProperty external_id
            if ($ttpId) {
                $groupTTPs[$groupName] += $ttpId
            }
        }
    }

    # Comparer avec les TTP extraits
    $results = $groupTTPs.Keys | ForEach-Object {
        $matching = $groupTTPs[$_] | Where-Object { $myTTPs -contains $_ } | Sort-Object -Unique
        if ($matching.Count -gt 0) {
            [PSCustomObject]@{
                GroupName    = $_
                MatchCount   = $matching.Count
                MatchingTTPs = ($matching -join ", ")
            }
        }
    } | Where-Object { $_ }

    # Affichage final
    if ($results.Count -gt 0) {
        Write-Host "`n==== TOP GROUPES IDENTIFIÉS ====" -ForegroundColor Cyan
        $results | Sort-Object MatchCount -Descending | Select-Object -First 10 | Format-Table -AutoSize
    } else {
        Write-Host "Aucun groupe correspondant trouvé dans ATT&CK." -ForegroundColor Yellow
    }
}