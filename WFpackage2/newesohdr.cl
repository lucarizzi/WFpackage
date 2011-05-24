# ESOHDR -- Convert raw header to something that can be used by MSCRED.

procedure esohdr (input)

string	input			{prompt="List of raw ESO MEF files"}
bool	querytype = yes		{prompt="Query for observation type?"}
int	namps = 1		{prompt="Number of amps per CCD"}
int	ntransient = 2		{prompt="Number of bad transient columns"}
file	wcsdb = "esodb$wcs.db"  {prompt="WCS database"}
bool	redo = no		{prompt="Redo?"}
string	obstype			{prompt="Observation type", mode="q",
				 enum="zero|dark|flat|object"}
bool	new			{prompt="Obs after 2000?"}
struct	*fd1, *fd2

begin
	file	inlist, extlist, hdr
	file	in, ext
	string	key
	struct	value
	int	chipindex,chipnx, chipny, chipx, chipy,win1binx,win1biny, now, index
	int	outnx, outny, outx, outy, outindex
	int	outprscx, outovscx, outprscy, outovscy
	int	x1, x2, y1, y2
	bool	done
	real 	gain
	
	set fkinit = "append,padlines=30,ehulines=30"
	inlist = mktemp ("tmp$iraf")
	extlist = mktemp ("tmp$iraf")
	hdr = mktemp ("tmp$iraf")

	sections (input, option="fullname", > inlist)

####### LR
	index=1
#####################

	fd1 = inlist
	while (fscan (fd1, in) != EOF) {
	    if (!imaccess (in//"[0]"))
		next
	    hselect (in//"[0]", "ESOHDR", yes) | scan (key)
	    if (nscan() == 1)
		done = yes
	    else
		done = no
	    if (!redo && done)
		next

	    hselect (in//"[0]", "title", yes) | scan (value)
	    printf ("%s: %s\n", in, value)

	    mscextensions (in, output="file", index="1-", extname="", extver="",
		lindex+, lname-, lver-, ikparams="", > extlist)

	    # Convert HIERARCH keywords to normal keywords.

	if(new) {
	    if (!done) {
		# This step is to pad the headers in one pass rather
		# than letting the FITS kernel do it.
		msccmd ("imcopy $input $output verbose-", in, in)

		hfix (in//"[0]", command="newrmhierarch $fname $fname")
		fd2 = extlist
		while (fscan (fd2, ext) != EOF) {
		    hfix (ext, command="newrmhierarch $fname $fname")
		    hedit (ext, "INHERIT", "T", add+,
			del-, verify-, show-, update+)
		}
		fd2 = ""
		}
		}
	else {
	    if (!done) {
		# This step is to pad the headers in one pass rather
		# than letting the FITS kernel do it.
		msccmd ("imcopy $input $output verbose-", in, in)

		hfix (in//"[0]", command="esohdrfix $fname $fname")
		fd2 = extlist
		while (fscan (fd2, ext) != EOF) {
		    hfix (ext, command="esohdrfix $fname $fname")
		    hedit (ext, "INHERIT", "T", add+,
			del-, verify-, show-, update+)
		}
		fd2 = ""
		}	
	}
	    # Setup mosaic processing keywords.
	    # Observation type.
	    #if (querytype)
		ccdhedit (in, "imagetyp", obstype, extname="",
		    type="string")

if (new) {

######## LR  THE WIN1BINX and WIN1BINY KEYWORDS ARE NO MORE IN ALL THE EXTENSIONS, BUT ONLY IN THE 0th 
		hselect(in//"[0]", "WIN1BINX,WIN1BINY", yes) | scan (win1binx,win1biny)
		print ("Adesso comincio con le estensioni....")

	    fd2 = extlist
	    while (fscan (fd2, ext) != EOF) {
		if (index>4) {now=13-index}
		else {now=index}

		hselect (ext,
		"CHI"//now//"INDE,CHI"//now//"X,CHI"//now//"Y,CHI"//now//"NX,CHI"//now//"NY", yes) |
		    scan (chipindex,chipx,chipy,chipnx,chipny)

		hselect (ext, "OUT"//now//"INDE,OUT"//now//"X,OUT"//now//"Y,OUT"//now//"NX,OUT"//now//"NY", yes) |
		    scan (outindex, outx, outy, outnx, outny)
		hselect (ext, "OUT"//now//"PRSX,OUT"//now//"OVSX,OUT"//now//"PRSY,OUT"//now//"OVSY", yes) |
		    scan (outprscx,outovscx,outprscy,outovscy)

		# GAIN: TRASFORM OUT1CONA in OUTCONAD
		print("Addind OUTCONAD keyword to mantain compatibility")
		hselect (ext,"OUT"//now//"CONA",yes) | scan(gain)
		hedit (ext,"OUTCONAD",gain,add+,upd+,ve-)

		## THIS HAS BEEN DONE TO HAVE A SINGLE KEYWORD CONTAINING THE GAIN VALUE


		# IMAGEID
		if (namp == 1)
		    printf ("%d\n", chipindex) | scan (value)
		else
		    printf ("%d%d\n", chipindex, outindex) | scan (value)
		hedit (ext, "IMAGEID", value, add+,
		    del-, verify-, show-, update+)

		# EXTNAME
		if (namp == 1)
		    printf ("im%d\n", chipindex) | scan (value)
		else
		    printf ("im%d%d\n", chipindex, outindex) | scan (value)
		hedit (ext, "EXTNAME", value, add+,
		    del-, verify-, show-, update+)

		# CCDSIZE
		printf ("[1:%d,1:%d]\n", chipnx, chipny) | scan (value)
		hedit (ext, "CCDSIZE", value, add+,
		    del-, verify-, show-, update+)

		# CCDSUM
		printf ("%d %d\n", win1binx, win1biny) | scan (value)
		hedit (ext, "CCDSUM", value, add+,
		    del-, verify-, show-, update+)

		# DETSEC
		if (chipy == 1) {
		    y1 = outy
		    if (outindex == 1) {
			x1 = outx - outnx + 1
		    } else if (outindex == 2) {
			x1 = outx
		    }
		} else if (chipy == 2) {
		    y1 = outy - outny + 1
		    if (outindex == 1) {
			x1 = outx
		    } else if (outindex == 2) {
			x1 = outx - outnx + 1
		    }
		}
		x2 = x1 + outnx - 1
		y2 = y1 + outny - 1
		printf ("[%d:%d,%d:%d]\n", x1, x2, y1, y2) | scan (value)
		hedit (ext, "DETSEC", value, add+,
		    del-, verify-, show-, update+)

		# CCDSEC
		x1 = 1
		y1 = 1
		x2 = outnx
		y2 = outny
		printf ("[%d:%d,%d:%d]\n", x1, x2, y1, y2) | scan (value)
		hedit (ext, "CCDSEC", value, add+,
		    del-, verify-, show-, update+)

		# AMPSEC
		if (chipy == 1) {
		    y1 = 1
		    y2 = outny
		    if (outindex == 1) {
			x1 = outnx
			x2 = 1
		    } else if (outindex == 2) {
			x1 = 1
			x2 = outnx
		    }
		} else if (chipy == 2) {
		    y1 = outny
		    y2 = 1
		    if (outindex == 1) {
			x1 = 1
			x2 = outnx
		    } else if (outindex == 2) {
			x1 = outnx
			x2 = 1
		    }
		}
		printf ("[%d:%d,%d:%d]\n", x1, x2, y1, y2) | scan (value)
		hedit (ext, "AMPSEC", value, add+,
		    del-, verify-, show-, update+)

		# DATASEC
		if (chipy == 1) {
		    y1 = 1 + outprscy
		    if (outindex == 1)
			x1 = 1 + outovscx
		    else if (outindex == 2)
			x1 = 1 + outprscx
		} else if (chipy == 2) {
		    y1 = 1 + outovscy
		    if (outindex == 1)
			x1 = 1 + outprscx
		    else if (outindex == 2)
			x1 = 1 + outovscx
		}
		x2 = x1 + outnx - 1
		y2 = y1 + outny - 1
		printf ("[%d:%d,%d:%d]\n", x1, x2, y1, y2) | scan (value)
		hedit (ext, "DATASEC", value, add+,
		    del-, verify-, show-, update+)

		# LTV
		x1 = x1 - 1
		y1 = y1 - 1
		hedit (ext, "LTV1", x1, add+, del-, verify-, show-, update+)
		hedit (ext, "LTV2", y1, add+, del-, verify-, show-, update+)

		# BIASSEC
		if (chipy == 1) {
		    if (outindex == 1)
			x1 = 1
		    else if (outindex == 2)
			x1 = 1 + outprscx + outnx
		} else if (chipy == 2) {
		    if (outindex == 1)
			x1 = 1 + outprscx + outnx
		    else if (outindex == 2)
			x1 = 1
		}
		x2 = x1 + outovscx - 1
		printf ("[%d:%d,*]\n", x1, x2, y1, y2) | scan (value)
		hedit (ext, "BIASSEC", value, add+,
		    del-, verify-, show-, update+)

		# TRIMSEC
		if (chipy == 1) {
		    y1 = 1 + outprscy
		    if (outindex == 1) {
			x1 = 1 + outovscx
			x2 = outovscx + outnx - ntransient
		    } else if (outindex == 2) {
			x1 = 1 + outprscx + ntransient
			x2 = outprscx + outnx
		    }
		} else if (chipy == 2) {
		    y1 = 1 + outovscy
		    if (outindex == 1) {
			x1 = 1 + outprscx + ntransient
			x2 = outprscx + outnx
		    } else if (outindex == 2) {
			x1 = 1 + outovscx
			x2 = outovscx + outnx - ntransient
		    }
		}
		y2 = y1 + outny - 1
		printf ("[%d:%d,%d:%d]\n", x1, x2, y1, y2) | scan (value)
		hedit (ext, "TRIMSEC", value, add+,
		    del-, verify-, show-, update+)

		# AMPNAME
		hedit (ext, "AMPNAME", "(CHI"//now//"ID//OUT"//now//"NAME)", add+,
		    del-, verify-, show-, update+)
		print("EXTENSION "//now//" FINISHED")
######## LR 
		index=index+1
###########################

	    }
		now=1
	    fd2 = ""
	    delete (extlist, verify-)

	}
else {		    fd2 = extlist
	    while (fscan (fd2, ext) != EOF) {
		hselect (ext,
		"CHIPINDE,CHIPX,CHIPY,CHIPNX,CHIPNY,WIN1BINX,WIN1BINY", yes) |
		    scan (chipindex,chipx,chipy,chipnx,chipny,win1binx,win1biny)
		hselect (ext, "OUTINDEX,OUTX,OUTY,OUTNX,OUTNY", yes) |
		    scan (outindex, outx, outy, outnx, outny)
		hselect (ext, "OUTPRSCX,OUTOVSCX,OUTPRSCY,OUTOVSCY", yes) |
		    scan (outprscx,outovscx,outprscy,outovscy)

		# IMAGEID
		if (namp == 1)
		    printf ("%d\n", chipindex) | scan (value)
		else
		    printf ("%d%d\n", chipindex, outindex) | scan (value)
		hedit (ext, "IMAGEID", value, add+,
		    del-, verify-, show-, update+)

		# EXTNAME
		if (namp == 1)
		    printf ("im%d\n", chipindex) | scan (value)
		else
		    printf ("im%d%d\n", chipindex, outindex) | scan (value)
		hedit (ext, "EXTNAME", value, add+,
		    del-, verify-, show-, update+)

		# CCDSIZE
		printf ("[1:%d,1:%d]\n", chipnx, chipny) | scan (value)
		hedit (ext, "CCDSIZE", value, add+,
		    del-, verify-, show-, update+)

		# CCDSUM
		printf ("%d %d\n", win1binx, win1biny) | scan (value)
		hedit (ext, "CCDSUM", value, add+,
		    del-, verify-, show-, update+)

		# DETSEC
		if (chipy == 1) {
		    y1 = outy
		    if (outindex == 1) {
			x1 = outx - outnx + 1
		    } else if (outindex == 2) {
			x1 = outx
		    }
		} else if (chipy == 2) {
		    y1 = outy - outny + 1
		    if (outindex == 1) {
			x1 = outx
		    } else if (outindex == 2) {
			x1 = outx - outnx + 1
		    }
		}
		x2 = x1 + outnx - 1
		y2 = y1 + outny - 1
		printf ("[%d:%d,%d:%d]\n", x1, x2, y1, y2) | scan (value)
		hedit (ext, "DETSEC", value, add+,
		    del-, verify-, show-, update+)

		# CCDSEC
		x1 = 1
		y1 = 1
		x2 = outnx
		y2 = outny
		printf ("[%d:%d,%d:%d]\n", x1, x2, y1, y2) | scan (value)
		hedit (ext, "CCDSEC", value, add+,
		    del-, verify-, show-, update+)

		# AMPSEC
		if (chipy == 1) {
		    y1 = 1
		    y2 = outny
		    if (outindex == 1) {
			x1 = outnx
			x2 = 1
		    } else if (outindex == 2) {
			x1 = 1
			x2 = outnx
		    }
		} else if (chipy == 2) {
		    y1 = outny
		    y2 = 1
		    if (outindex == 1) {
			x1 = 1
			x2 = outnx
		    } else if (outindex == 2) {
			x1 = outnx
			x2 = 1
		    }
		}
		printf ("[%d:%d,%d:%d]\n", x1, x2, y1, y2) | scan (value)
		hedit (ext, "AMPSEC", value, add+,
		    del-, verify-, show-, update+)

		# DATASEC
		if (chipy == 1) {
		    y1 = 1 + outprscy
		    if (outindex == 1)
			x1 = 1 + outovscx
		    else if (outindex == 2)
			x1 = 1 + outprscx
		} else if (chipy == 2) {
		    y1 = 1 + outovscy
		    if (outindex == 1)
			x1 = 1 + outprscx
		    else if (outindex == 2)
			x1 = 1 + outovscx
		}
		x2 = x1 + outnx - 1
		y2 = y1 + outny - 1
		printf ("[%d:%d,%d:%d]\n", x1, x2, y1, y2) | scan (value)
		hedit (ext, "DATASEC", value, add+,
		    del-, verify-, show-, update+)

		# LTV
		x1 = x1 - 1
		y1 = y1 - 1
		hedit (ext, "LTV1", x1, add+, del-, verify-, show-, update+)
		hedit (ext, "LTV2", y1, add+, del-, verify-, show-, update+)

		# BIASSEC
		if (chipy == 1) {
		    if (outindex == 1)
			x1 = 1
		    else if (outindex == 2)
			x1 = 1 + outprscx + outnx
		} else if (chipy == 2) {
		    if (outindex == 1)
			x1 = 1 + outprscx + outnx
		    else if (outindex == 2)
			x1 = 1
		}
		x2 = x1 + outovscx - 1
		printf ("[%d:%d,*]\n", x1, x2, y1, y2) | scan (value)
		hedit (ext, "BIASSEC", value, add+,
		    del-, verify-, show-, update+)

		# TRIMSEC
		if (chipy == 1) {
		    y1 = 1 + outprscy
		    if (outindex == 1) {
			x1 = 1 + outovscx
			x2 = outovscx + outnx - ntransient
		    } else if (outindex == 2) {
			x1 = 1 + outprscx + ntransient
			x2 = outprscx + outnx
		    }
		} else if (chipy == 2) {
		    y1 = 1 + outovscy
		    if (outindex == 1) {
			x1 = 1 + outprscx + ntransient
			x2 = outprscx + outnx
		    } else if (outindex == 2) {
			x1 = 1 + outovscx
			x2 = outovscx + outnx - ntransient
		    }
		}
		y2 = y1 + outny - 1
		printf ("[%d:%d,%d:%d]\n", x1, x2, y1, y2) | scan (value)
		hedit (ext, "TRIMSEC", value, add+,
		    del-, verify-, show-, update+)

		# AMPNAME
		hedit (ext, "AMPNAME", "(CHIPID//OUTNAME)", add+,
		    del-, verify-, show-, update+)

	    }
	    fd2 = ""
	    delete (extlist, verify-)
	}
	    # WCS
	    if (access (wcsdb)) {
		match ("WCSASTRM", wcsdb, stop-) | scan (key, key, key, value)
		if (nscan() > 3)
		    hedit (in//"[0]", "WCSASTRM", value, add+,
			del-, verify-, show-, update+)
		if (!done)
		    hedit (in//"[0]", "RA", "(RA/15)", add+,
			del-, verify-, show-, update+)
		mscsetwcs (in, wcsdb, ra="ra", dec="dec",
		    ra_offset=0., dec_offset=0.)
	    } else {
		printf ("WARNING: WCS database not found (%s)", wcsdb)
		printf (" - WCS not set\n")
	    }

	    time | scan (value)
	    hedit (in//"[0]", "ESOHDR", value, add+,
		    del-, verify-, show-, update+)
	}
	fd1 = ""; delete (inlist, verify-)
end



