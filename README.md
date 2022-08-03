# sports, simple ports

My shell version of this ports system has some nifty features, like support for git repositories. There's tons of software you have to compile yourself from git. This manages those programs, the compilation, installation and deinstallation.

# How to install sports:
```
sudo install -o $USER -d /usr/sports
git clone https://github.com/hboetes/sports.git /usr/sports
cd /usr/sports/core/pkgutils/
./bootstrap
```
# How to use them.

```
cd /usr/sports/opt/emacs
pkgmk -i
```

# How to write your own ports.
Just look at a few other ports. It's pretty simple actually.
