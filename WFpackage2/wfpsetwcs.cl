# WFPSETWCS -- Set the Mosaic WCS from a database and RA/Dec header keywords.
#
# If no database is specified (a value of "") then only the CRVAL are updated.

#-- V. 2.0 Nov.2007

procedure wfpsetwcs (images, database)

string	images			{prompt="Mosaic images"}
file	database = "wfpddb$ASTROSOL_"		{prompt="WCS database"}
#bool	wcssol = no		{prompt="Add WCSSOL keyword ?"}
bool	wcssol = no		{prompt="do not change, obsolete"}
string	ra = "ra"		{prompt="Right ascension keyword ?"}
string  unit = "hours"		{prompt="Unit of the right ascension keyword?", enum="deg|hours"}
string	dec = "dec"		{prompt="Declination keyword (degrees)"}
real	ra_offset = 0.		{prompt="RA offset (arcsec)"}
real	dec_offset = 0.		{prompt="Dec offset (arcsec)"}
bool	reset=yes		{prompt="Delete RA/DEC offsets keywords ? "}

struct	*extlist

begin
	file	db, inlist, image, imgfile
	string	ims, extname, uni
	real	raval, decval
        real    ra_off,dec_off
	bool	addwcs, rese
	int 	lines

	cache imextensions

	ims = images
	db = database
	#addwcs = wcssol
	addwcs = no
        ra_off = ra_offset
        dec_off = dec_offset
	rese=reset
	uni=unit

	raval = 0.
	decval = 0.
	inlist = mktemp ("tmp$iraf")
	imgfile = mktemp ("tmp$iraf")

	sections (ims, option="fullname", >imgfile)

#- case "reset":
	if (rese)   {
		print("Reset mode: deleting RA/DEC_OFFS keywords")
		extlist=imgfile
		while(fscan(extlist,image)!=EOF) {
			print("Image: "//image)
			hedit(image//"[0]", "RA_OFFS,DEC_OFFS", add-, del+ , veri-, upd+, show-)
			hedit(image//"[0]", "MSCCMATC", add-, del+ , veri-, upd+, show-)
                        #print("Ignoring USER DEFINED OFFSETS...")
                        ra_off=0
                        dec_off=0
			}
		}


#- case "NOreset":
        if (!rese) {
                print("Writing USER DEFINED offsets to image header...")
                extlist=imgfile
                while(fscan(extlist,image)!=EOF) {
                      print("Image: "//image)
         	      hedit (image//"[0]","RA_Offs", ra_off, add+, del-, ve-, show+, update+)
	              hedit (image//"[0]","DEC_Offs", dec_off, add+, del-, ve-, show+, update+)
                       }
         }


	imextensions (ims, output="file", index="1-", extname="",
	    extver="", lindex=no, lname=no, lver=no, ikparams="", > inlist)
	count(inlist) | scan(lines)

	if (lines<1) {
	del(inlist, ve-)
	imextensions (ims, output="file", index="0-", extname="",
	    extver="", lindex=no, lname=no, lver=no, ikparams="", > inlist)
			}

	extlist = inlist

	while (fscan (extlist, image) != EOF) {
	    if (db != "") {
		hselect (image, "extname", yes) | scan (extname)
                if (nscan()==0 && lines<1) {
			print ("No EXTNAME keyword, assuming EXTNAME=im0")
                        extname="im0"
                        }
		print("Adding the solution "//extname//" to image "//image)
		ccsetwcs (image, db, extname, xref=INDEF, yref=INDEF,
		    xmag=INDEF, ymag=INDEF, xrotation=INDEF, yrotation=INDEF,
		    lngref=INDEF, latref=INDEF, lngunits="", latunits="",
		    transpose=no, projection="tan", coosystem="j2000",
		    update=yes, verbose=no)
	if (addwcs) {hedit(image,fields="WCSSOL",value=db//" "//extname, 
			add=yes, del=no, veri-, upd=yes, show+) }
	    }

	    hselect (image, ra//","//dec, yes) | scan (raval, raval,decval,decval)
	### COMPATIBILITA' CON IL CASO IN CUI LA RA E DEC SIA ESPRESSA UNA SOLA VOLTA

	   if (nscan()<3) {
		hselect (image, ra//","//dec, yes) | scan (raval,decval)
			}
	#########################################################
		decval = decval + dec_off / 3600.
		if (uni=="hours") {raval = raval * 15.0 + ra_off / 3600. /
		    cos (decval/57.29577851) }
		else {raval = raval  + ra_off / 3600. /
		    cos (decval/57.29577851) }
		hedit (image, "crval1", raval, add+, del-, update+,
		    show-, verify-)
		hedit (image, "crval2", decval, add+, del-, update+,
		    show-, verify-)

		if (rese) { hedit(image, "MSCCMATC", add-, del+ , veri-, upd+, show-) }
	}
	extlist = ""; delete (inlist, verify=no)
end
