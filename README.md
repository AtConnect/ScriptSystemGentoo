# Script déploiement Centreon pour Wazo/Xivo

This script has been writed by Kévin Perez for AtConnect Anglet

![asciicast](http://www.atconnect.net/images/header/logo.png)
![image](https://image.noelshack.com/fichiers/2019/17/3/1556112297-telechargement.png)

## Compatible with Debian 7/8/9 only.
#### Need Bash 4.2 at least to run.

# Step 1 - Run update and install git
```
apt-get update && apt-get install git-core -y && apt-get install curl -y

```
# Step 2 - Clone the repository and install it
```
cd /tmp
git clone https://github.com/AtConnect/ScriptWazoXivoDeploiement
cd ScriptWazoXivoDeploiement
chmod a+x lancercescriptsurwazoxivo.sh
./lancercescriptsurwazoxivo.sh
```


## Versions
- **2.5** Kévin Perez
  - *Fix:* `ssl` enable and force ssl
  - *Fix:* `openssl` install to solve an error of ssl on certain system
  - *Fix:* `doc` for debian 8 sources , and the update of a key
- **2.0** Kévin Perez
  - *New:* New design
  - *Fix:* `grammar error` in command_nrpe  
  - *Fix:* Stop the script if `Debian 6`
  - *Fix:* Stop the script if a `past install` has been runned
- **1.0** Kévin Perez
  - *New:* Repository deleted


### Further information in the event that the xivo-five sources are outdated */etc/apt/sources.list.d/xivo-dist.list* :
```
deb http://mirror.xivo.solutions/debian/ xivo-five main
deb http://mirror.xivo.solutions/debian/ xivo-five-candidate main
deb http://mirror.xivo.solutions/debian/ xivo-five-oldstable main
```

### If your key is outdated, update your key like that
```
wget http://mirror.xivo.solutions/xivo_current.key -O - | apt-key add -
```

### If you have a problem of *debian 8* sources list, reset */etc/apt/sources.list* to :
```
deb http://ftp.fr.debian.org/debian/ jessie main
deb http://security.debian.org/ jessie/updates main
```
