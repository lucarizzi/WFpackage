# Package script for the wfpd package
#{ WFPDRED - Wide Field Padova Reduction Software


#if (! defpac ("stsdas")) {
#	print("STSDAS not defined")
#    if (deftask ("stsdas")) {
#		print("Task stsdas not defined")
#		if (defpar ("stsdas.motd")) {
#		    stsdas.motd = no
#			print("Loading analysis")
#	            stsdas
#		    #	print("Loading fitting")
#		    #analysis
#		    #fitting
#	        } else {
#		       print("Loading analysis")
#		    stsdas
#		    #analysis
#		    #   print("Loading fitting")
#		    #fitting
#	        }
#    } else {
#        type "wfpddir$lib/warning.dat"
#    }
#}
#;
#if (defpac ("stsdas")) {
#		print("done")
#		analysis
#		fitting
#		}


noao
digiphot
daophot
apphot
nproto
mscred
esowfi
 
    
package wfpdred


print ("     *****************************************************************")
print ("     **                WELCOME IN THE WFPDRED PACKAGE               **")
print ("     **                                                             **")
print ("     **                    Version 1.0 April 2001                   **")
print ("     **                                                             **")
print ("     **	                Project Scientist: E.V.Held		    **")
print ("     **              Software Development: L.Rizzi                  **")
print ("     **              Padova Astronomical Observatory                **")
print ("     **							            **")
print ("     **	     This package is property of the Padova Astronomical    **")
print ("     **      Observatory. Do not copy, distribute or modify the     **")
print ("     **	     code without previous authorization from the Authors   **")
print ("     *****************************************************************")


task	wfpzero		= "wfpddir$wfpzero.cl"
task 	wfpcat		= "wfpddir$wfpcat.cl"
task 	wfpcat2		= "wfpddir$wfpcat2.cl"
task	wfpcomb		= "wfpddir$wfpcomb.cl"
task    wfpcenter	= "wfpddir$wfpcenter.cl"
task 	wfpphot		= "wfpddir$wfphot.cl"
task	wfpfit		= "wfpddir$wfpfit.cl"
# task	wfcterm1	= "wfpddir$wfcterm1.cl"
task	wfpfind		= "wfpddir$wfpfind.cl"
task    wfpastro	= "wfpddir$wfpastro.cl"
# task    wfphfix		= "wfpddir$wfphfix.cl"
task	newesohdr	= "wfpddir$newesohdr.cl"
task	newrmhierarch	= "wfpddir$newrmhierarch.cl"
task    wfpsetwcs	= "wfpddir$wfpsetwcs.cl"
# task	wfprefsol	= "wfpddir$wfprefsol.cl"
task	wfptnxsol	= "wfpddir$wfptnxsol.cl"
task    wfpsetup	= "wfpddir$wfpsetup.cl"
task	wfpnorm		= "wfpddir$wfpnorm.cl"
# task 	wfpconvert	= "wfpddir$wfpconvert.cl"
task    select_int	= "wfpddir$select_int.e"
task    ident_wfp	= "wfpddir$ident_wfp.e"

ident_wfp
hidetask select_int
hidetask ident_wfp
hidetask newesohdr
hidetask newrmhierarch
clbye()
