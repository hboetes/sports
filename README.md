# Cruxports for Linux

My shell version of cruxports has some nifty additions, like support for git repositories. There's tons of software you have to compile yourself from git. This c4L manages those programs, the compilation, installation and deinstallation.

# How to install cruxports:
```
sudo install -o $USER -d /usr/cruxports
git clone --recurse-submodules https://github.com/hboetes/cruxports_linux.git /usr/cruxports
cd /usr/cruxports/core/pkgutils/
./bootstrap
```
# How to use them.

```
cd /usr/cruxport/opt/emacs
pkgmk -i
```

# How to write your own ports.
Just look at a few other ports. It's pretty simple actually.
