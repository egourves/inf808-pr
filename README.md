# INF808 - Projet recherche : simulation d'un APT avec Caldera

[![Build LaTeX document](https://github.com/egourves/inf808-pr/actions/workflows/latex.yml/badge.svg)](https://github.com/egourves/inf808-pr/actions/workflows/latex.yml)

## Déploiement avec Docker

Le fichier `docker-compose.yml` dans le dossier `docker` permet de déployer les conteneurs suivants :
- Caldera
- Un conteneur contenant un service d'upload servant de cible
- Un conteneur tailscale pour exposer Caldera sur le tailnet
- Un conteneur tailscale pour exposer la cible sur le tailnet

> Avant de lancer le projet, il faut cloner le dépôt caldera dans le dossier caldera.
> Il suffit de lancer la commande suivante :

```shell
git clone --recursive https://github.com/mitre/caldera docker/caldera
```

Le fichier `Caldera_plugins_fix.sh` peut être nécessaire lorsque certains modules de Caldera ne sont pas initialisés. Il suffit alors de copier le fichier `Caldera_plugins_fix.sh` dans le dossier caldera, puis on peut utiliser la commande suivante :

```shell
podman run --rm -v $PWD:/app:z ubuntu ./app/Caldera_plugins_fix.sh
```

> Si vous rencontrez une erreur liés aux volumes à cause des commandes précédentes, essayez d'enlever l'option `:z` après les volumes.
> Cette option est utile sur les environments où SELinux est actif.

Dans le dossier `docker` se trouve un fichier contenant des variables environnement `.env`, un exemple est proposé avec `.env.example`. Il contient les clés d'authentification nécessaires pour que les conteneurs puissent rejoindre un tailnet de Tailscale.

Pour exposer les pages web dans le tailnet on peut utiliser la commande `tailscale serve` :
```shell
podman exec -it ts-caldera tailscale serve --bg 8888
```

Cette commande permet d'exposer automatiquement Caldera en HTTPS à l'aide de Tailscale.

## Compilation LaTeX

Dans le dossier `.github` se trouve un fichier de configuration pour lancer des Github Actions qui permettent de compiler les fichiers LaTeX lorsque ceux-ci sont modifiés sur la branche `main`

## Scripts Powershell

Le script `Get-TTP.ps1` permet d'obtenir les TTPs générées dans les Windows Event par Aurora.

Pour obtenir les TTPs les plus communes (nombre d'occurence), on peut utiliser la commande suivante :
```powershell
.\Get-TTP.ps1 | Group-Object -Property TPP | ForEach-Object {     [PSCustomObject]@{
         TTP = $_.Name  # Reuse the category from the original objects
         Count = $_.Count
         EventDetail = $_.Group  # Retain the original objects in the group
     }} | Sort-Object -Property Count
```

Un exemple de sortie du script avec la commande précédente :
```powershell
T1027.004     1 {@{TPP=T1027.004; EventTime=2025-04-05T23:38:37.487153400Z; Level=2; …
T1047         1 {@{TPP=T1047; EventTime=2025-04-05T23:17:51.812186200Z; Level=2; Pare…
T1059.001     2 {@{TPP=T1059.001; EventTime=2025-04-06T00:45:33.106045900Z; Level=2; …
T1562.004     2 {@{TPP=T1562.004; EventTime=2025-04-05T23:09:57.467157400Z; Level=2; …
T1053.005     7 {@{TPP=T1053.005; EventTime=2025-04-05T23:38:51.527068600Z; Level=2; …
T1560.001    18 {@{TPP=T1560.001; EventTime=2025-04-06T02:24:49.288111200Z; Level=3; …
T1087.002    27 {@{TPP=T1087.002; EventTime=2025-04-06T02:26:21.033853800Z; Level=3; …
T1219       224 {@{TPP=T1219; EventTime=2025-04-06T02:20:57.869721300Z; Level=2; Pare…
```

Pour mettre en lien les TTPs générées dans les Windows Event par Aurora avec des groupes (APT) présent sur mitre, on peut réutiliser la commande précédente en ajoutant le script Match_APT_with_TTP :
```powershell
.\Get-TTP.ps1 | Group-Object -Property TPP | ForEach-Object {     [PSCustomObject]@{
         TTP = $_.Name  # Reuse the category from the original objects
         Count = $_.Count
         EventDetail = $_.Group  # Retain the original objects in the group
     }} | Sort-Object -Property Count | .\Match-TTP-ATP.ps1
```

Il est possible d'automatiser les tâches sur Windows à l'aide d'un planificateur de tâche qui enverra le résultat de la commande ci-dessus par mail à l'aide de cette commande : 
```powershell
$body = .\Get-TTP.ps1 | Group-Object -Property TPP | ForEach-Object {     [PSCustomObject]@{
                 TTP = $_.Name  # Reuse the category from the original objects
                 Count = $_.Count
                 EventDetail = $_.Group  # Retain the original objects in the group
             }} | Sort-Object -Property Count | .\Match-TTP-ATP.ps1 | Out-String
$params = @{
    To = 'NetworkAdmin@inf808.com'
    From = 'no-reply-psh@inf808.com'
    Subject = 'APT link Report'
    Body = $body
    SmtpServer = 'smtp.inf808.com'
}
Send-MailMessage @params
```