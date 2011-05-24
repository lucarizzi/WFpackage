procedure wffind(images)

file		images		{prompt="Mosaic images to be searched for?", filetype="x"}
string		list		{prompt="Extensions to be searched for (number or all) ? "}
string		template	{prompt="Template for output catalogs ?"}
string		type		{prompt="Output type (logical|wcs) ?", enum="logical|wcs"}
real		seeing		{prompt="Seeing (in pixels) ?"}
real		thresh=20	{prompt="Finding threshold (in sigma above the background)?"}
pset		findpars	{prompt="Other finding parameters "}
string		instr = "wfi2p2" {prompt = "Which instrument ?"}
struct		*testo, *imglist

begin
	string 		ins, ins_file, arg1, im, tmpl, lst, convuni
	int		maxext, i, j, n_ext, extn
	real		xdim, ydim, conv_def, ron_def, sky, rms, arg2, th, conv, in_num
	string		key_exp, key_conv, key_ron, key_air, key_filt, str2
	file		imgfile, tmptbl


tmptbl=mktemp("tmp$tmptbl")
################# SETUP PROCEDURE FOR SPECIFIED INSTRUMENT
#	if (ins == "wfi@2p2") ins_file = "wfpddb$wfi2p2.dat"
#	testo=ins_file

#	while(fscan(testo, arg1, arg2) != EOF) {
#		if (arg1=="KEYWORDS") break
#		if (arg1=="extensions") maxext=arg2
#		if (arg1=="xdim")       xdim=arg2
#		if (arg1=="ydim")       ydim=arg2
#		if (arg1=="conv_def")   conv_def=arg2
#		if (arg1=="ron_def")    ron_def=arg2
#		}
#	while(fscan(testo, arg1, str2) != EOF) {
#		if (str2=="NONE") 	str2=""
#		if (arg1=="exptime")    key_exp=str2
#		if (arg1=="convfact")   key_conv=str2
#		if (arg1=="ron")        key_ron=str2
#		if (arg1=="airmass")    key_air=str2
#		if (arg1=="filter")     key_filt=str2
#	}
#	print("CCD SETUP for "//ins)
#	print("Extensions  -> "//maxext)
#	print("Dimensions  -> "//xdim//" x "//ydim//" pixels")
#	print("Gain        -> "//conv_def//" or keyword "//key_conv)
#	print("RON         -> "//ron_def//"  or keyword "//key_ron)

	th=thresh
	ins = instr
	# sostituito con il run di wfpsetup all'inizio dell'utilizzo
	#wfpsetup(instrument=ins)
	ins="wfpddb$"//ins//".dat"

	testo=ins

	while(fscan(testo, arg1, arg2) != EOF) {
		if (arg1=="KEYWORDS") break
		if (arg1=="conv_def")   conv_def=arg2
		if (arg1=="ron_def")    ron_def=arg2
		}
	while(fscan(testo, arg1, str2) != EOF) {
		if (str2=="NONE") 	str2=""
		if (arg1=="convfact")   key_conv=str2
		if (arg1=="ron")        key_ron=str2
		if (arg1=="units") 	convuni=str2

		}

	if (convuni=="ADU") {	#print("Warning: Conversion factor and RON in ADUs")
				#print("Header values have been converted to electrons")

				conv_def=1/conv_def
				ron_def=ron_def*conv_def
				conv=conv_def
				key_conv=""
				key_ron=""}


##### EXPAND IMAGE LIST
	imgfile=mktemp("tmp$zero")
	sections (images, option="fullname", > imgfile)
	tmpl=template
	lst=list

#### BEGIN OPERATIONS TO BE DONE FOR EACH IMAGE
	imglist = imgfile
	while (fscan(imglist, im) != EOF) {
		print("********************************************")
		print("* Searching for stars on image: "//im)
		print("********************************************")

		imextensions(im, output="none", index="1-", extname="", extver="")
		n_ext=imextensions.nimages 
	extn=INDEF
	if (lst!="all") {extn=int(lst)}

	if (n_ext==0) n_ext=1
	for (j=1; j<=n_ext; j+=1) {
		if (n_ext==1) i=0 
		else i=j
	if (lst!="all" && i!=extn) next

		findthresh.images=im//"["//i//"]"
		findthresh.section="[*,*]"
		findthresh.center="midpt"
		del("tmptbl",ve-,>>&"errors")
		in_num=0
		if (key_conv!="NONE") {hselect(im//"["//i//"]",key_conv,yes) | scan (in_num)}
		if (in_num==0) {in_num=conv_def}				#

#		datapars.gain=key_conv						#
#		datapars.epadu=conv_def						#

		findthresh.gain=in_num						#
		print("CCD Gain set to "//in_num)
		findthresh.readnoi=ron_def		
		print("CCD RON  set to "//ron_def)			#
		findthresh(nframes=1,ve-, > "tmptbl")

		findpars.thresho=th
		findpars.nsigma=1.5

		datapars.fwhmpsf=see
#		datapars.exposur=key_exp
#		datapars.airmass=key_air
#		datapars.filter=key_filt					#

		testo="tmptbl"
		while(fscan(testo, rms, sky)!=EOF) {
			datapars.sigma=rms
			print("Sky sigma of extension "//i//" -> measured: "//sky//" computed: "//rms//" ADUs")
			}

############### FIND STARS
#		datapars.readnoi=ron_def					#
		del("tmptbl",ve-,>>&"errors")
		del(tmpl//"pixel_"//i,ve-,>>& "errors")
		del(tmpl//"_"//i,ve-,>>& "errors")
		print("Finding stars...")
		daofind(im//"["//i//"]",output=tmpl//"pixel_"//i,interact-,verify-, verb-)
if (typ=="wcs") {
############## FROM PIXEL TO SKY COORDINATES
		wcsctran(tmpl//"pixel_"//i, tmpl//"_"//i, im//"["//i//"]", "logical", "world", columns="1 2", units="", formats="%.3H %.2h", min_sig=9, verbose-)
		del(tmpl//"pixel_"//i, ve-)
	}
else {
	copy(tmpl//"pixel_"//i, tmpl//"_"//i)
	del(tmpl//"pixel_"//i, ve-)
	}
		} ### FINE OPERAZIONI DA RIPETERE PER OGNI CCD

}   ### FINE OPERAZIONI DA FARE PER OGNI IMMAGINE
end









