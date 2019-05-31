# Script déploiement Centreon pour Gentoo

This script has been writed by Kévin Perez for AtConnect Anglet

![asciicast](http://www.atconnect.net/images/header/logo.png)
![image](https://image.noelshack.com/fichiers/2019/17/3/1556112297-telechargement.png)

## Compatible with Genton 4 and more
#### Need Bash 4.2 at least to run.

# Step 1 - Run update and install git
```
apt-get update && apt-get install git-core -y && apt-get install curl -y

```
# Step 2 - Clone the repository and install it
```
cd /tmp
git clone https://github.com/AtConnect/ScriptSystemGentoo
cd ScriptSystemGentoo
chmod a+x lancercescriptsurgentoo.sh
./lancercescriptsurgentoo.sh
```


## Versions

- **1.0** Kévin Perez
  - *New:* Repository deleted
