procedure wfpnorm (images, names)

file	images		{prompt="Images to be normalized?"}
file	names		{prompt="Names for the normalized images?"}
file	col_file	{prompt="Name of the color equations file?"}
string	refext		{prompt="Number of reference extension ?"}
string	filter		{prompt="Filter (TEMPORARY!) ?"}
bool	addsky		{prompt="Add back the average sky level ?"}
bool	usersky		{prompt="Add a user defined sky level ?"}
real	uservalue	{prompt="User sky value ?"}
bool	trasf		{prompt="Move sky areas according to dithering ?"}

struct	*fd1, *fd2, *fd3, *fd4
begin

file	inlist, outlist, im, errors, normlist, norm
string	imag,nam,colfile, flt, ref, imref
int	count1,count2,i, j, x1,x2,y1,y2, nccd, n_ext
string	ccd,mag,color,zerop, extname, junk, xcenter, ycenter
real	zeroref, zero, ratio, xc, yc, dim, sky, sky_avg, uval
bool	add, tra, usky
	
	inlist = mktemp ("tmp$inl")
	errors = mktemp("tmp$err")
	normlist = mktemp("tmp$norm")




################# READ PARAMETERS
	imag=images
	nam=names
	colfile=col_file
	ref=refext
	flt=filter
	add=addsky
	usky=usersky
	uval=userval
	dim=100
	tra=trasf
	del("log_wfpnorm", ve-,>>&errors)
	if (usky && add) {
		print("ERROR! I cannot add both the average sky level")
		print("       and the user defined sky level.")
		print("	      Please, specify only one option!")
		return
		}

################## EXPAND TEMPLATES	
	sections (imag, option="fullname", > inlist)
	sections (nam,option="fullname", > normlist)
	count(inlist) | scan(count1)
	count(normlist) | scan(count2)
	if (count1!=count2) {print("Different number of input and output images. Aborting")
				return
				}
	
################ BEGIN LOOP ON IMAGES
	fd1=inlist
	### record reference image name
	while(fscan(fd1,im)!=EOF) {imref=im
		print("##### IMAGE "//imref//" will be used as reference for sky areas")
		imextensions(imref, output="none", index="1-", extname="", extver="")
		n_ext=imextensions.nimages 		
		print("##### IMAGE "//imref//" contains "//n_ext//" extensions")
		nccd=n_ext
		break
		}
	fd1=inlist # rewind list
	fd3=normlist
	del("tmp_*.fits", ve-, >>&errors)
	while(fscan(fd1,im)!=EOF) {
		### READ OUTPUT IMAGE NAME
		if (fscan(fd3,norm)!=EOF) junk=""
		print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
		print("Now working on image: "//im//" to generate image:"//norm)
		print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
		sky_avg=0

		### SPLIT EXTENSION
		#mscsplit(im,output="tmp",mefext=".fits", ver+, del-)
		### READ THE VALUE FOR REFERENCE EXTENSION
		fd2=colfile
		while(fscan(fd2,ccd,mag,color,zerop)!=EOF) {
			if(ccd!=ref) next
			if(mag!=flt) next
			zeroref=real(zerop)
			}
		print("Reference extension: "//ref//" with mag zero point:"//zeroref)
		for(i=1;i<=nccd;i=i+1) {
		        # DO NOT UNCOMMENT THESE LINES!!!!
			#if (i==int(ref)) {
				#print("Extension "//i//" is reference. Copied without correction")
				#imcopy(im//"["//i//"]", "tmp_"//i//".fits", ve-)
				#hselect(im//"["//i//"]", "EXTNAME", yes) | scan(extname)
				#hedit("tmp_"//i//".fits", "EXTNM", extname, add+, upd+, verify-, show-)
				#hedit("tmp_"//i//".fits", "EXTNAME", extname, add+, upd+, verify-, show-)
				#next
				#}
			### READ ZERO POINT FOR CURRENT EXTENSION
			fd2=colfile
			while(fscan(fd2,ccd,mag,color,zerop, junk, junk, junk, junk, junk, junk, xcenter, ycenter)!=EOF) {
				if(mag!=flt) next
				if(int(ccd)!=i) next
				zero=real(zerop)	
				xc=real(xcenter); yc=real(ycenter)

				## IF NOT REFERENCE IMAGE, TRANSFORM COORDINATES OF SKY REGION
				if (im!=imref) {
					del("coo", ve-, >>&errors)
					print(xc//" "//yc, >> "coo")
					del("trans", ve-, >>&errors)
					mscctran("coo", "trans", imref//"["//i//"]","logical", "world", colu="1,2", 
						min_sig=14, ve-)
					del("coo", ve-)
					mscctran("trans", "coo", im//"["//i//"]", "world", "logical", colu="1,2",
						min_sig=14, ve-)
					del("trans", ve-)
					fd4="coo"
					while(fscan(fd4,xc,yc)!=EOF) {junk=""}
				}
				print("***************** EXTENSION "//i//" ********************")		
				print("Zero point for extension "//i//" -> "//zero)
				print("Center of sky region ("//xc//","//yc//")")
				break		}	
			### MEASURE SKY LEVEL
			x1=int(xc-dim/2)
			x2=int(xc+dim/2)
			y1=int(yc-dim/2)
			y2=int(yc+dim/2)
			
			imstat(im//"["//i//"]["//x1//":"//x2//","//y1//":"//y2//"]",fields="midpt", format-) | scan (sky)
			print("Sky level of region ["//x1//":"//x2//","//y1//":"//y2//"] -> "//sky)
			sky_avg=sky_avg+sky
			print("subtracting sky level...")
			imarith(im//"["//i//"]", "-", sky, "tmp_"//i//".fits")
			### PERFORM ARITHMETICS
			if (i!=int(ref)) {
				ratio=10**(-0.4*(zero-zeroref))
				printf("Scaling extension %2d with ratio %6.3f.\n", i, ratio)
				imarith("tmp_"//i//".fits", "*", ratio, "tmp_"//i//".fits")
				}
			hselect(im//"["//i//"]", "EXTNAME", yes) | scan(extname)
			hedit("tmp_"//i//".fits", "EXTNM", extname, add+, upd+, verify-, show-)
			hedit("tmp_"//i//".fits", "EXTNAME", extname, add+, upd+, verify-, show-)
				}
			### BUILD EXTENSION 0
			imcopy(im//"[0]", "tmp_0.fits", ve-)
			### Making new mosaic
			mscjoin(input="tmp",output=norm, ve+, del+)
			# REMOVE EXTNM
			msccmd("hedit $input EXTNM del+ ve- upd+", norm)
			if (add) {
			sky_avg=sky_avg/nccd
			print("***************** ADDING AVERAGE SKY LEVEL ****************")
			print("       Average level -> "//sky_avg)
			mscarith(norm, "+", sky_avg, norm, ve+)
			print(im//"   "//sky_avg, >> "log_wfpnorm")
			}
			if (usky) {
			print("***************** ADDING USER DEFINED SKY LEVEL ****************")
			print("       Defined level -> "//uval)
			mscarith(norm, "+", uval, norm, ve+)
			print(im//"   "//uval, >> "log_wfpnorm")
			}	

		}



############# STRIPPING .FITS OR .IMH FROM REFERENCE IMAGE
#	ncar=strlen(ref)
#	if (ncar>5 && substr(ref, ncar-4, ncar) == ".fits")
#		ref=substr (ref,1,ncar-5)
#	else if (ncar >4 && substr (ref, ncar-3, ncar) == ".imh")
#		ref=substr (ref,1, ncar-4)


end










