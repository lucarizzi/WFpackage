# MSCSETWCS -- Set the Mosaic WCS from a database and RA/Dec header keywords.
#
# If no database is specified (a value of "") then only the CRVAL are updated.

procedure wfpsetwcs (images, database)

string	images			{prompt="Mosaic images"}
file	database = ""		{prompt="WCS database"}
string	ra = "ra"		{prompt="Right ascension keyword (hours)"}
string	dec = "dec"		{prompt="Declination keyword (degrees)"}
real	ra_offset = 0.		{prompt="RA offset (arcsec)"}
real	dec_offset = 0.		{prompt="Dec offset (arcsec)"}

struct	*extlist

begin
	file	db, inlist, image
	string	ims, extname
	real	raval, decval

	cache imextensions

	ims = images
	db = database

	raval = 0.
	decval = 0.

	inlist = mktemp ("tmp$iraf")
	imextensions (ims, output="file", index="", extname="",
	    extver="", lindex=no, lname=yes, lver=no, ikparams="", > inlist)

	extlist = inlist
	while (fscan (extlist, image) != EOF) {
	    if (db != "") {
		hselect (image, "extname", yes) | scan (extname)
		ccsetwcs (image, db, extname, xref=INDEF, yref=INDEF,
		    xmag=INDEF, ymag=INDEF, xrotation=INDEF, yrotation=INDEF,
		    lngref=INDEF, latref=INDEF, lngunits="", latunits="",
		    transpose=no, projection="tan", coosystem="j2000",
		    update=yes, verbose=no)
	    }

	    hselect (image, ra//","//dec, yes) | scan (raval, raval,decval,decval)
	   
		decval = decval + dec_offset / 3600.
		raval = raval * 15. + ra_offset / 3600. /
		    cos (decval/57.29577851) 
		hedit (image, "crval1", raval, add+, del-, update+,
		    show-, verify-)
		hedit (image, "crval2", decval, add+, del-, update+,
		    show-, verify-)
	   
	}
	extlist = ""; delete (inlist, verify=no)
end
