
procedure wfpsetup (camera)

string camera = "wfi2p2" {prompt="Identifier of your camera", enum="wfi2p2|vimos|hawki|int|lbc|aao|cfh12k|megaprime|suprimecam|INDEF"}
#file   instrument = "?" {prompt="Current Instrument_Table (omit .DAT), or '?'", mode="q"}



#--- PROBLEMA: VA IN TILT SE instrument NON E' DEFINITO --> TESTARE !!
file   instrument = "?" {prompt="Current Instrument_Table (omit .DAT), or '?'"}




struct *fd_1



#-------------

begin

string 	current
string  arg1, str1, str2,name, datab, cam
string  key_exp, key_conv, key_ron, key_air, key_filt, convuni
real    arg2, xdim, ydim, conv_def, ron_def, conv, n_ext
file	ins





#- EVH: now, run the ad-hoc setup procedure according to the different CAMERAs:

cam = camera

#-------------------------------------------------------------------------
#- EVH: WARNING: check the compatibility of our setup against "esosetins"
#-------------------------------------------------------------------------

#-- if (ins=="wfi2p2" && deftask("esosetinst")) {  
#- EVH: replace by the 'camera' concept:

	if (cam=="wfi2p2") {
		esowfi
		print("camera=wfi@2p2, i.e. new ESOWFI. Running esosetinst...")
		esosetinst
		#- wfpzero.wcs = "esodb$wcs.db"
		#- wfpsetwcs.database = "esodb$wcs.db"
	}

	if (cam=="vimos") {
		print("ad-hoc setup for VIMOS not yet implemented, assuming INDEF")
	}

	if (cam=="hawki") {
		print("ad-hoc setup for HAWK-I not yet implemented, assuming INDEF")
	}

	if (cam=="int") {
		print("ad-hoc setup for INT not yet implemented, assuming INDEF")
	}

	if (cam=="lbc") {
		print("ad-hoc setup for LBC not yet implemented, assuming INDEF")
	}

	if (cam=="aao") {
		print("ad-hoc setup for AAO not yet implemented, assuming INDEF")
	}

	if (cam=="cfh12k") {
		print("ad-hoc setup for CFH12K not yet implemented, assuming INDEF")
	}

	if (cam=="megaprime") {
		print("ad-hoc setup for MEGAPRIME not yet implemented, assuming INDEF")
	}

	if (cam=="suprimecam") {
		print("ad-hoc setup for SUPRIMECAM not yet implemented, assuming INDEF")
	}


#- EVH: now look for the current instrument_table (may change in time !): 
#- Back to Luca's since WFPfind/phot/zero/tnxsol assume "wfpddb$" for ins_file !

datab = envget("wfpddb")
chdir wfpddb$

ins=instrument
if (ins=="?") {
	ins=""
	print("------------------------------ Configuration files in ",datab)
	files ("*.dat")
	print(" ")
	print("Enter the name of the instrument, omit  .DAT extension")
	#dir (files="*.dat", long-, ncols=1)
	ins=instrument
		}	

name=ins//".dat"
print ("... reading instrument file ",ins)


while (!access(name)) {	print("WARNING: instrument not available")
			print("Please check the list of instrument...")
			files ("*.dat")
			#dir (files="*.dat", long-, ncols=1)
			ins=instrument
			name=ins//".dat"
		}


	fd_1=name

	while(fscan(fd_1, arg1, arg2) != EOF) {
		if (arg1=="KEYWORDS") 	break
		if (arg1=="extensions") n_ext=arg2
		if (arg1=="xdim")       xdim=arg2
		if (arg1=="ydim")       ydim=arg2
		if (arg1=="conv_def")   conv_def=arg2
		if (arg1=="ron_def")    ron_def=arg2
		}
	while(fscan(fd_1, arg1, str2) != EOF) {
		if (str2=="NONE") {	print("Warning: the keyword "//arg1//" is not available")
					print("The package will use default values")
					print("Please ignore error messages ... ")
					str2="NOT PRESENT"}
		if (arg1=="exptime")    key_exp=str2
		if (arg1=="convfact")   key_conv=str2
		if (arg1=="ron")        key_ron=str2
		if (arg1=="airmass")    key_air=str2
		if (arg1=="filter")     key_filt=str2
		if (arg1=="units")	convuni=str2
	}

	if (convuni=="ADU") {	print("Warning: Conversion factor and RON in ADUs")
				print("Header values have been converted to electrons")

				conv_def=1/conv_def
				ron_def=ron_def*conv_def
				conv=conv_def
				key_conv=""
				key_ron=""}


	print("*******************************************************")
	print("CCD SETUP for "//ins)
	print("Extensions  -> "//n_ext)
	print("Dimensions  -> "//xdim//" x "//ydim//" pixels")
	print("Gain        -> "//conv_def//" or keyword "//key_conv)
	print("RON         -> "//ron_def//"  or keyword "//key_ron)
	print("*******************************************************")



#- EVH: set useful defaults for all cameras/instrument_files:

	print("Updating APPHOT/CCMAP/DATAPARS/CENTERPARS parameters...")
	unlearn apphot
	unlearn center
	#
	ccmap.insystem="j2000"
	ccmap.project="tnx"
	ccmap.fitgeom="general"
	ccmap.xxorder=4
	ccmap.xyorder=4
	ccmap.yyorder=4
	ccmap.yxorder=4
	ccmap.xxterms="half"
	ccmap.yxterms="half"
	#print("Updating DATAPARS parameters...")
#-EVH:
	datapars.scale=1.0
#-
	datapars.gain=key_conv						
	datapars.epadu=conv_def						
	datapars.exposur=key_exp
	datapars.airmass=key_air
	datapars.filter=key_filt					
	datapars.readnoi=ron_def	
	#print("Updating CENTERPARS parameters...")
	centerpars.calgori="centroid"
	centerpars.cbox=30
	centerpars.cthresh=10
	centerpars.minsnra=10
	centerpars.maxshift=20
	centerpars.clean=yes
	#print("Updating MSCDPARS parameters...")
	if (deftask("mscdpars")) {
		print("Task mscdpars defined. Ok for MSCRED version < 4.0")
		mscdpars.scale=1
		mscdpars.emissio=yes
		mscdpars.ccdread=key_ron
		mscdpars.gain=key_conv
		mscdpars.readnoi=ron_def
		mscdpars.epadu=conv_def
		mscdpars.exposure=key_exp
		mscdpars.airmass=key_air
		mscdpars.filter=key_filt
		}
	else {
		print("Task mscdpars not defined. This is ok for MSCRED version > 4.4 ")
		}
	print("Configuring single tasks ...")
	#print("WFCTERM does not need configuration")


#- EVH: pre-define the instrument_file in the package tree:

	wfpastro.instr=ins
	print("WFPASTRO updated")
	#print("WFPCAT  does not need configuration")
	wfpcenter.instr=ins
	print("WFPCENTER updated")
	#print("WFPCOMB does not need configuration")
	wfpfind.instr=ins
	print("WFPFIND updated")
	#wfphot.instr=ins  !changed by EVH
	wfpphot.instr=ins
	print("WFPHOT updated")
	#print("WFPREFSOL is obsolete and works only with wfi@2p2 images")
	print("WFPTNXSOL currently works only on wfi@2.2 images")
	wfptnxsol.instr=ins
	wfpzero.instr=ins
	print("WFPZERO updated")
	print("##################### WARNING #####################")
	print("# DO NOT MODIFY THE INSTR PARAMETER OF THE SINGLE #")
	print("# TASKS: RE-RUN WFPSETUP IF YOU WANT TO SWITCH TO #")
	print("# A DIFFERENT INSTRUMENT/TELESCOPE                #")
	print("###################################################"

	
	print("WORKING DIRECTORY:")
	back
	print("*******************************************************")
	fd_1=""
end
