procedure wfpcomb (images, name, ref)

file	images			{prompt="Images to be combined?"}
file	name			{prompt="Template name for the combined images?"}
file	ref			{prompt="Name of reference image?"}
int	ext_ref			{prompt="Extension to be used as reference?"}
bool    keep=yes		{prompt="Keep transformed images?"}
string	extens = "ask"		{prompt="Extensions to be combined?", enum="all|ask"}
bool	inters = "yes"		{prompt="Output image is intersection of images"}
int	xgrid = 20		{prompt="Number of points for grid determination (x) ?"}
int     ygrid = 40		{prompt="Number of points for grid determination (y) ?"}
bool	flux = no		{prompt="Preserve image flux (always no) ?"}
string  combine = "average"	{prompt="Type of combine operation?", enum="average|median"}
pset	imcombine		{prompt="Other combine parameters"}
string	format="extensions"	{prompt="Output format (extensions|full_image)?", enum="extensions|full_image"}
pset	mscimage		{prompt="mscimage parameters (if format=full_image)"}
pset	mscstack		{prompt="mscstack parameters (if format=full_image)"}
struct  *fd_coord
struct  *fd_ima
struct  *fd_ima_int
struct  *fd_out
struct  *testo
bool	answ			{prompt="(yes/no) ?",mode="q"}


begin

file	inlist, outlist,extlist, errors, output, inlist_int, comb_list
int	nc, nl, nx, ny, xmax, xmin, ymax, ymin, i, n_ext, ext, n, _ext_ref
real	x,y, xc, yc, xc_ref, yc_ref
file	coord, db, tmpin, tmpout, tmpref, comb, offsets
string  ext_check, fmt
bool	answ0, first, flu, keepint, intersect

string  combint, rejectint, im, ima, re, na, ref_off
int     nlowint, nhighint, nkeepint, xtrim, ytrim, xtrim_pos, xtrim_neg
int	ytrim_pos, ytrim_neg, ncar
real    lthrint, hthrint

	nx=xgrid
	ny=ygrid
	coord = mktemp ("tmp$iraf")
	comb_list=mktemp("tmp$comb_list")
	db = mktemp ("tmp$iraf")
	inlist = mktemp ("tmp$inl")
	inlist_int = mktemp ("tmp$inl")
	extlist = mktemp ("tmp$ext")
	tmpin = mktemp ("tmp$tmpin")
	tmpout = mktemp ("tmp$tmpout")
	tmpref = mktemp ("tmp$tmpref")
	comb = mktemp ("tmp$comb")
	offsets = mktemp("tmp$offs")
	errors = mktemp("tmp$err")

        combint = combine
	intersect=inters
	keepint = keep
	_ext_ref=ext_ref
	flu=flux
	fmt=format
        #rejectint = reject
        #nlowint = nlow
        #nhighint = nhigh
        #lthrint = lthreshold
        #hthrint = hthreshold


	imcombine.combine=combint
	#imcombine.reject=rejectint
	#imcombine.nlow=nlowint
        #imcombine.nhigh=nhighint 
        #imcombine.lthreshold=lthrint 
        #imcombine.hthreshold=hthrint 

	#imcombine.rejmask=""
	#imcombine.plfile=""
	#imcombine.sigma=""
	imcombine.project=no
	imcombine.outtype="real"
	#imcombine.masktype="none"
	#imcombine.blank=0
	#imcombine.scale="none"
	#imcombine.zero="none"
	#imcombine.weight="none"

################## EXPAND IMAGE TEMPLATES	
	sections (images, option="fullname", > inlist)
	sections (images, option="fullname", > inlist_int)


################## READ PARAMETERS (2)
	ext_check=extens
	re = ref
######  NO REFERENCE IMAGE SPECIFIED
	if (re=="") {
		print ("No reference image specified. Using first image...")
	fd_ima = inlist
	if (fscan(fd_ima, re)!=EOF) {re=re}
	fd_ima=""
		print ("Using "//re//" as the refence image")
		}
	

	fd_ima = inlist
	output = name
	first=yes
	del("extensions", ve-, >>& errors)


################################################  FULL IMAGE GENERATION USING MSCIMAGE + MSCSTACK
	if (fmt=="full_image") {
		while(fscan(fd_ima, im)!=EOF) {
			ncar=strlen(im)
			if (ncar>5 && substr(im, ncar-4, ncar) == ".fits")
			im=substr (im,1,ncar-5)
			else if (ncar >4 && substr (im, ncar-3, ncar) == ".imh")
			im=substr (im,1, ncar-4)
			ncar=strlen(re)
			if (ncar>5 && substr(re, ncar-4, ncar) == ".fits")
			re=substr (re,1,ncar-5)
			else if (ncar >4 && substr (re, ncar-3, ncar) == ".imh")
			re=substr (re,1, ncar-4)
			if (access(im//"_ima.fits")) {
				print("Warning! Image: "//im//"_ima.fits already exists!")
				del(im//"_ima.fits", ve+)
				if (access(im//"_ima.fits")) {
					print("You chose not to delete the output file")
					print("I don't know where to write the output image...aborting")
					#return
					}
				}
			if (!access(im//"_ima.fits")) {
			## create mosaic image
			if (deftask("mscdpars")) {
				print("Using MSCRED 4.0 or older!")
				print("Changing syntax....")
				mscimage(input=im//".fits", output=im//"_ima.fits", reference=re//"_ima.fits", ve+)
				}
			if (!deftask("mscdpars")) {
				print("Using MSCRED 4.4!")
				print("Changing syntax ... and using extension "//_ext_ref//" for reference")
				mscimage(input=im//".fits", output=im//"_ima.fits", reference=re//"["//_ext_ref//"].fits", ve+)
				}
			}
			print(im//"_ima.fits", >> comb_list)
			}
		mscstack("@"//comb_list, output//"_FULL.fits")
		#ref=re//"_ima.fits"
		if (intersect) {
			# compute the center of the reference image in world coordinates
				# determine if the combined images are multiextensions or not
				fd_ima=comb_list
				while(fscan(fd_ima,im)!=EOF) {
					imextensions (im, output="file", index="1-", extname="", extver="", 
					lindex=yes, lname=no, lver=no, ikparams="")
					n_ext=int(imextensions.nimages)	
					#if (n_ext==0) {	
					#	imextensions (im, output="file", index="0-", extname="", extver="", 
					#	lindex=yes, lname=no, lver=no, ikparams="")
					#	n_ext=int(imextensions.nimages)	
					#	}
					print("Images to be trimmed contain "//n_ext//" extensions")
					ref_off = im
					print("Image "//ref_off//" will be used for offset computation")
					break
				}
			# nel caso in cui siano a singola estensione:
			if (n_ext==0) {
					
				#hselect(re//"_ima.fits", "naxis1, naxis2", yes) | scan (nc, nl)
				hselect(ref_off, "naxis1, naxis2", yes) | scan (nc, nl)
				xc_ref=nc/2
				yc_ref=nl/2
				#print("SCRIVO NC e NL:"//nc//" "//nl)
				print("0    0", > offsets)
				print(xc_ref//" "//yc_ref, > tmpin)
				#print("sono prima di mscctran da eseguire con"//tmpin//" "//tmpref//" "//ref)
				#mscctran(tmpin,tmpref,re//"_ima.fits","logical","world",columns="1 2", units="", formats="%.3H %.2h",verbose-, min_sig=10)
				mscctran(tmpin,tmpref,ref_off,"logical","world",columns="1 2", units="", formats="%.3H %.2h",verbose-, min_sig=10)
				#print("passato mscctran")
				fd_ima=comb_list
				while(fscan(fd_ima,ima)!=EOF) {
					#print("Confronto "//ima//" e "//re//" oppure "//ref)
					if (ima!=re//"_ima.fits") {
						#print("Altro mscctran")
						mscctran(tmpref, tmpout, ima//"[0]", "world", "logical", columns="1 2", units="hours native", formats="", verbose-)
						#print("Passato anche questo")
						fd_out=tmpout
						while(fscan(fd_out, xc, yc) !=EOF) {
						xc=xc_ref-xc
						yc=yc_ref-yc
						printf('%.3f %.3f \n',xc,yc, >> offsets)
						}
					del(tmpout, ve-)				
					}				
				}
			
			print("Computing  intersection region...")
			#Determinazione zona di intersezione.
			fd_coord=offsets
			xtrim_pos=0; xtrim_neg=0; ytrim_pos=0; ytrim_neg=0
			while(fscan(fd_coord, x,y)!=EOF) {
				if (x>0 && x>xtrim_pos) xtrim_pos=x
				if (x<0 && x<xtrim_neg) xtrim_neg=x
				if (y>0 && y>ytrim_pos) ytrim_pos=y
				if (y<0 && y<ytrim_neg) ytrim_neg=y
				}
			xtrim=xtrim_pos-xtrim_neg+6
			ytrim=ytrim_pos-ytrim_neg+6		
			hselect(output//"_FULL.fits", "naxis1, naxis2", yes) | scan (nc, nl)
			nc=nc-xtrim
			nl=nl-ytrim
			print("Intersection zone on the combined image: ["//xtrim//":"//nc//","//ytrim//":"//nl//"]")
			imcopy(output//"_FULL.fits["//xtrim//":"//nc//","//ytrim//":"//nl//"]", "temporary.fits", ve-)
			imdel(output//"_FULL.fits", ve-)
			imrename("temporary.fits",output//"_FULL.fits")
			}

			# nel caso in cui siano multi estensione
			if (n_ext!=0) {
				print("Computing offsets ...")
				hselect(ref_off//"[1]", "naxis1, naxis2", yes) | scan (nc, nl)
				xc_ref=nc/2
				yc_ref=nl/2
				print("0    0", > offsets)
				print(xc_ref//" "//yc_ref, > tmpin)
				mscctran(tmpin,tmpref,ref_off//"[1]","logical","world",
				columns="1 2", units="", formats="%.3H %.2h",verbose-)
				fd_ima=comb_list
				while(fscan(fd_ima,ima)!=EOF) {
				if (ima!=re) {
					mscctran(tmpref, tmpout, ima//"[1]", "world", "logical", columns="1 2", units="hours native", formats="", verbose-)
					fd_out=tmpout
					while(fscan(fd_out, xc, yc) !=EOF) {
					xc=xc_ref-xc
					yc=yc_ref-yc
					printf('%.3f %.3f \n',xc,yc, >> offsets)
						}
					del(tmpout, ve-)				
					}				
				}
			
			print("Computing intersection region...")
			#Determinazione zona di intersezione.
			fd_coord=offsets
			xtrim_pos=0; xtrim_neg=0; ytrim_pos=0; ytrim_neg=0
			while(fscan(fd_coord, x,y)!=EOF) {
				if (x>0 && x>xtrim_pos) xtrim_pos=x
				if (x<0 && x<xtrim_neg) xtrim_neg=x
				if (y>0 && y>ytrim_pos) ytrim_pos=y
				if (y<0 && y<ytrim_neg) ytrim_neg=y
				}
			xtrim=xtrim_pos-xtrim_neg+6
			ytrim=ytrim_pos-ytrim_neg+6
			mscsplit(output//"_FULL.fits", output="temp", ve+, del-)		
			hselect("temp_1.fits", "naxis1, naxis2", yes) | scan (nc, nl)
			nc=nc-xtrim
			nl=nl-ytrim
			print("Intersection zone on the combined image: ["//xtrim//":"//nc//","//ytrim//":"//nl//"]")
			for (i=1; i<=n_ext; i=i+1) { 
				print("Trimming extension "//i)
				imcopy("temp_"//i//".fits["//xtrim//":"//nc//","//ytrim//":"//nl//"]", "temporary.fits", ve-)
				imdel("temp_"//i//".fits", ve-)
				#imrename("temporary.fits",output//"_ext"//i//".fits")
                                imrename("temporary.fits", "temp_"//i//".fits")
				}
			del(output//"_FULL.fits", ve-)
			mscjoin("temp", output=output//"_FULL.fits", del+, ve+)
			
			}
			}
		}

################################################# GENERATING SINGLE IMAGES .....
	if(fmt=="extensions") {

################## CHECK THE NUMBER OF EXTENSIONS AND EXPAND LIST
	while(fscan(fd_ima, im)!=EOF) {
		imextensions (im, output="file", index="1-", extname="", extver="", 
		lindex=yes, lname=no, lver=no, ikparams="", >> extlis)
		n_ext=int(imextensions.nimages)	
		print("Il valore di n_ext e':"//n_ext)
		if (n_ext==0) {
			imextensions (im, output="file", index="0-", extname="", extver="", 
			lindex=yes, lname=no, lver=no, ikparams="", >> extlist)
			n_ext=int(imextensions.nimages)	
				}
		if (first) {
			first=no
			del(extlist, ve-)
			if (ext_check=="ask") {
				print("Images contain "//n_ext//" extensions.")
				for (i=1; i<= n_ext; i+=1) {
						printf("Combine extension -> %d ", i)
						answ0=answ
						if (answ0) {    j=i 
							if (n_ext==1) j=0 
							print(j, >>"extensions")
							   }
							   }
	
			                      }

		else if (imextensions.nimages != n_ext && n_ext!=1) {
			print("Images have different number of extensions. Exiting.")
			fd_ima=""
			return
			                                            }
		           }
			}
	if (ext_check=="all") {
		print("Combining all extensions.")
		if (n_ext==1) print (0,>>"extensions")
		if (n_ext!=1) {
			for(i=1; i<=n_ext; i+=1) print(i, >>"extensions")
				}
		 
		}
	
			

################# LOOP ON EXTENSIONS
	testo="extensions"
	while (fscan(testo, ext) != EOF) {
	fd_ima=inlist

################# LOOP ON IMAGES
	while (fscan(fd_ima, im)!=EOF) {

################# STRIPPING .FITS AND .IMH 
	ncar=strlen(im)
	if (ncar>5 && substr(im, ncar-4, ncar) == ".fits")
		im=substr (im,1,ncar-5)
	else if (ncar >4 && substr (im, ncar-3, ncar) == ".imh")
		im=substr (im,1, ncar-4)
################ CHECK WHETHER THE CORRECTED IMAGE IS ALREADY ON THE DISK
	na=im//"_ext"//ext
		if (imaccess (na)) {
			printf("WARNING: Image '%s' already exists. Skipping. \n", na)
			next
			}
############### BUILD THE GRID FOR THE TRANSFORMATION
		hselect(im//"["//ext//"]", "naxis1, naxis2", yes) | scan (nc, nl)
	xmin = (nc - 1)/(nx - 1)
	ymin = (nl - 1)/(ny - 1)
	for (ymax=1; ymax<=nl+1; ymax=ymax+ymin)
		for (xmax=1; xmax<=nc+1; xmax=xmax+xmin)
		print (xmax, ymax, xmax, ymax, >> coord)

############## TRANSFORM THE GRID X,Y IN ALPHA, DELTA USING HIGH ORDER TERMS	
	mscctran (coord, db, im//"["//ext//"]", "logical", "world", columns="1 2", units="",formats="%.3H %.2h", min_sigdigit=9, verb-)
	delete (coord, ve-)

############## TRANSFORMS THE GRID ALPHA, DELTA IN X,Y USING ONLY THE LINEAR TERMS	
	wcsctran (db, coord, im//"["//ext//"]", "world", "logical", columns="1 2", units="hours native", formats="", min_sigdigit=9, ve-)
	delete(db, ve-)

############## CALCULATE TRANSFORMATION	
	geomap(coord, db, transforms="", xxorder=3, xyorder=3, yyorder=3,
		yxorder=3, xxterms="half", yxterms="half", reject=INDEF, xmin=INDEF, xmax=INDEF,ymin=INDEF, ymax=INDEF,
		calctype="double", verb-, interact-, results="")

############## APPLY TRANSFORMATION
	geotran(im//"["//ext//"]", na, db, coord, fluxcon=flux)
	del(db, ve-)
	del(coord, ve-)
	}
############## END LOOP ON IMAGES




############# STRIPPING .FITS OR .IMH FROM REFERENCE IMAGE
	ncar=strlen(re)
	if (ncar>5 && substr(re, ncar-4, ncar) == ".fits")
		re=substr (re,1,ncar-5)
	else if (ncar >4 && substr (re, ncar-3, ncar) == ".imh")
		re=substr (re,1, ncar-4)

############# LOOP ON IMAGES
	fd_ima_int = inlist_int
	while(fscan(fd_ima_int, im) != EOF) {
############ STRIPPING .FITS OR .IMH FROM IMAGE
	ncar=strlen(im)
	if (ncar>5 && substr(im, ncar-4, ncar) == ".fits")
		im=substr (im,1,ncar-5)
	else if (ncar >4 && substr (im, ncar-3, ncar) == ".imh")
		im=substr (im,1, ncar-4)

############# IF IMAGE IS REFERENCE PRINT "0 0" TO THE OFFSETS LIST, THE NAME 
############# TO THE COMBINE LIST AND TRANSFORM THE CENTER COORDINATE TO ALPHA, DELTA
		#print("Dovrei confrontare "//im//" con "//re)
		if (im==re) {
			#print("SONO QUI")
			na=im//"_ext"//ext
			print(na, >> comb)
			print("0 0", >> offsets)
			hselect(na, "naxis1, naxis2", yes) | scan (nc, nl)
			xc_ref=nc/2
			yc_ref=nl/2
			print(xc_ref//" "//yc_ref, > tmpin)
			page(tmpin)
			#!sleep 10
			#mscctran(tmpin,tmpref,na,"logical","world",
			#columns="1 2", units="", formats="%.3H %.2h",verbose-)
			mscctran(tmpin,tmpref,na,"logical","world",
			columns="1 2", units="", formats="",min_sig=20,verbose-)
			}
		else next
	}

############ FOR THE OTHER IMAGES, TRANSFORM ALPHA, DELTA INTO PIXEL AND 
############ CALCULATE OFFSETS
	fd_ima_int = inlist_int
	xc=0
	yc=0
	while(fscan(fd_ima_int, im) != EOF) {

########### STRIPPING .FITS OR .IMH
	ncar=strlen(im)
	if (ncar>5 && substr(im, ncar-4, ncar) == ".fits")
		im=substr (im,1,ncar-5)
	else if (ncar >4 && substr (im, ncar-3, ncar) == ".imh")
		im=substr (im,1, ncar-4)

		if (im!=re) {
			na=im//"_ext"//ext
			print(na, >>comb)
			mscctran(tmpref, tmpout, na, "world", "logical", columns="1 2", units="deg native", formats="", verbose-)
			page(tmpref)
			#!sleep 10
			page(tmpout)
			#!sleep 10
			fd_out=tmpout
			while(fscan(fd_out, xc, yc) !=EOF) {
			xc=xc_ref-xc
			yc=yc_ref-yc
			printf('%.3f %.3f \n',xc,yc, >> offsets)
						}
			del(tmpout, ve-)
			}
		else next
	}
	if (imaccess(output//"_ext"//ext//".fits")) {
		printf("WARNING: Image '%s' already exists. Skipping. \n", output//"_ext"//ext)
			del(tmpin, ve-)
			del(tmpref, ve-)
			del(comb, ve-)
			del(offsets, ve-)
		next}

############## COMBINE
	page(offsets)
	imcombine("@"//comb, output//"_ext"//ext, offsets=offsets)

############# CALCULATE INTERSECTION ZONE IF REQUIRED
	if (intersect) {
	print("Creating intersection image...")
	#Determinazione zona di intersezione.
	fd_coord=offsets
	xtrim_pos=0; xtrim_neg=0; ytrim_pos=0; ytrim_neg=0
	while(fscan(fd_coord, x,y)!=EOF) {
		if (x>0 && x>xtrim_pos) xtrim_pos=x
		if (x<0 && x<xtrim_neg) xtrim_neg=x
		if (y>0 && y>ytrim_pos) ytrim_pos=y
		if (y<0 && y<ytrim_neg) ytrim_neg=y
		}
	xtrim=xtrim_pos-xtrim_neg+1
	ytrim=ytrim_pos-ytrim_neg+1
	hselect(output//"_ext"//ext//".fits", "naxis1, naxis2", yes) | scan (nc, nl)
	nc=nc-xtrim
	nl=nl-ytrim
	print("Intersection zone on the combined image: ["//xtrim//":"//nc//","//ytrim//":"//nl//"]")
	imcopy(output//"_ext"//ext//".fits["//xtrim//":"//nc//","//ytrim//":"//nl//"]", "temporary.fits", ve-)
	imdel(output//"_ext"//ext//".fits", ve-)
	imrename("temporary.fits", output//"_ext"//ext//".fits")
	}

############ DELETE CORRECTED IMAGES AFTER COMBINING IF REQUIRED
	if (keepint!=yes) imdel("@"//comb, ve-)
	del(tmpin, ve-)
	del(tmpref, ve-)
	del(comb, ve-)
	del(offsets, ve-)

}
	}
	del(coord,ve-,>>&"errors")
	del(comb_list,ve-,>>&"errors")
	del(db ,ve-,>>&"errors")
	del(inlist ,ve-,>>&"errors")
	del(inlist_int ,ve-,>>&"errors")
	del(extlist,ve-,>>&"errors")
	del(tmpin,ve-,>>&"errors")
	del(tmpout,ve-,>>&"errors")
	del(tmpref,ve-,>>&"errors")
	del(comb,ve-,>>&"errors")
	del(offsets,ve-,>>&"errors")
	del(errors,ve-,>>&"errors")
	del ("extensions", ve-, >>&"errors")
	del ("errors", ve-)
end












