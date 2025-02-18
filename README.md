# INF808 - Projet recherche : simulation d'un APT avec Caldera

[![Build LaTeX document](https://github.com/egourves/inf808-projet/actions/workflows/latex.yml/badge.svg)](https://github.com/egourves/inf808-projet/actions/workflows/latex.yml)

## Déploiement avec Docker

Le fichier `docker-compose.yml` dans le dossier `docker` permet de déployer les conteneurs suivants :
- Caldera
- Un conteneur alpine servant de cible
- Un conteneur tailscale pour exposer Caldera sur le tailnet
- Un conteneur tailscale pour exposer la cible sur le tailnet

> Avant de lancer le projet, il faut cloner le dépôt caldera dans le dossier caldera.
> Il suffit de lancer la commande suivante :

```shell
git clone --recursive https://github.com/mitre/caldera docker/caldera
```

Le fichier `fix.sh` peut être nécessaire lorsque certains modules de Caldera ne sont pas initialisés. Il suffit alors de copier le fichier `fix.sh` dans le dossier caldera, puis on peut utiliser la commande suivante :

```shell
podman run --rm -v $PWD:/app:z ubuntu ./app/fix.sh
```

## Compilation LaTeX

Dans le dossier `.github` se trouve un fichier de configuration pour lancer des Github Actions qui permettent de compiler les fichiers LaTeX lorsque ceux-ci sont modifiés sur la branche `main`