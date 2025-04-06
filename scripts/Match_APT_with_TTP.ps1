# Accepter les données via le pipeline
$inputData = @()
if ($input) {
    $inputData = $input | ForEach-Object { $_ }
}

if ($inputData.Count -eq 0) {
    Write-Host "[-] Aucun TTP reçu en entrée. Assurez-vous de piper les données correctement." -ForegroundColor Red
    return
}

Write-Host "[+] Analyse des TTP extraits avec MITRE ATT&CK..." -ForegroundColor Cyan

# Extraire les TTP uniques
$myTTPs = $inputData | ForEach-Object { $_.TTP.Trim() } | Sort-Object -Unique

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

# Préparer une table de hachage pour accélérer les recherches
$attackPatterns = @{}
foreach ($obj in $attackData.objects | Where-Object { $_.type -eq "attack-pattern" }) {
    $attackPatterns[$obj.id] = $obj
}

# Parcourir les relations et associer les TTP aux groupes
foreach ($rel in $attackData.objects | Where-Object { $_.type -eq "relationship" -and $_.relationship_type -eq "uses" }) {
    $groupName = $groupNames[$rel.source_ref]
    if ($groupName -and $attackPatterns.ContainsKey($rel.target_ref)) {
        $ttpObj = $attackPatterns[$rel.target_ref]
        $ttpId = $ttpObj.external_references | Where-Object { $_.source_name -eq "mitre-attack" } | Select-Object -ExpandProperty external_id
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