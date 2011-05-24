#! /bin/csh -f
#- example (to copy/sync the entire directory 'prog' and its subdir.s):
#- set FROMDISK = /usr/users/held/prog
#- set TODISK = /diska/held/PROVA/

set FROMDISK = /iraf/extern/WFpackage
set TODISK = /iraf/extern/package.orig/

/usr/bin/rsync -nv -rlptg --delete $FROMDISK   $TODISK  
