In 2000 Per Liden started CRUX-Linux, a distro based on simplicity.  The
idea for the ports system was influenced by BSD ports, but written in sh
and C++, the Pkgfiles which define how a package  should  be  build  are
nothing but simple shell-scripts.

sports is a port/rewrite of the CRUX ports-system completely written
in zsh shell-script.

Now I hear you say: "What's wrong with the normal ports?" Well...  wrong
is a big word. It's just a matter of personal preference  I  think.  But
let me give you a list of reasons why I prefer sports.

 * Lightweight.
 * Always the latest versions of software, no matter which  release  you
   use.
 * sports are much easier to create and maintain since the ports are
   shell-based.
 * Portable, anyone can read and understand an sport.
 * Dependencies are optional.
 * It's not trying to be braindead-proof.
 * No checking of md5sum on uninstall of files.
 * Files in /etc are installed, and maintained with a  mergemaster  like
   application (rejmerge) in a sane and easy way.
 * Does not conflict with other package-managers.
 * You can build packages from alternative sources like binaries or git
