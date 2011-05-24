procedure wfpdstds(images, field)

file		images		 {prompt="Images containing standard stars ?"}
file		result		 {prompt="File with results ?"}
string		field		 {prompt="Standard field identification ?", mode="q"}
bool		center		 {prompt="Center standard stars ?"}
pset		photpars 	 {prompt="Photometry  parameters (-> :e) ?"}
pset		centerpars 	 {prompt="Centering   parameters (-> :e) ?"}
pset            fitskypars 	 {prompt="Sky fitting parameters (-> :e) ?"}
string		instr = "wfi2p2" {prompt="Which instrument ?"}
bool		display = no 	 {prompt="Display images being measured ?"}
string		stdfile="wfpddb$standards.landolt.pierre" {prompt="File with standard stars ?"}
struct		*fd1
struct 		*fd2
struct		*fd3, *imglist
struct		*fd4


begin

	file 	img, _stdcat, coords, coo, errors, stars, misu, coo_all, zero, ins_file, imgfile, std, transf
	string 	_field, id1, id2, act, dec_d, dec_m, dec_s, alp, dec, code, imname, id2_2, V, ins, key_airm, key_exp
	string  arg1, arg2, U_string, B_string, V_string, R_string, I_string, filter, junk, ap, junk1, junk2, ins_filt
	int	n, i, nc, nl, n_ext
	bool	find, cnt, first, disp
	real	x,y,sky, mag, magv, cterm, zerom, sigma, meanz, sum, area, pier, flux, magerr, tmp1, tmp2, _alp, _dec, airm
	file	_result, output, tmpf
	
	imgfile=mktemp("tmp$img")
	sections (images, option="fullname", > imgfile)
	imglist = imgfile

	_stdcat=stdfile
	coords=mktemp("tmp$coords")
	tmpf=mktemp("tmp$tmpf")	
	coo=mktemp("tmp$coo")
	coo_all=mktemp("tmp$coordinates")
	std=mktemp("tmp$stand")
	errors=mktemp("tmp$errors")
	stars=mktemp("tmp$stars")
	transf=mktemp("tmp$transf")
	misu=mktemp("tmp$misu")
	zero=mktemp("tmp$zero")
	output=mktemp("tmp$output")
	cnt=center
	ins=instr
	_result=result
	#if (ins=="wfi@2p2") ins_file="wfpddb$wfi2p2.dat"	
	#if (ins=="VLT") ins_file="wfpddb$VLT.dat"
	#if (ins=="INT") ins_file="wfpddb$INT.dat"
	disp=displ
	####### LOAD FILTER NAME CONVERSION TABLE AND INSTRUMENT SPECIFICATIONS
	U_string=""; B_string=""; V_string=""; R_string=""; I_string=""
	ins_file="wfpddb$"//ins//".dat"
	fd1=ins_file
	while(fscan(fd1, arg1, junk) != EOF) {
		if (arg1=="FILTER_NAME") break
		if (arg1=="filter") ins_filt=junk
		if (arg1=="airmass")     key_airm=junk
		if (arg1=="exptime") 	 key_exp=junk
	}
	
	while(fscan(fd1, arg1, arg2)!=EOF) {
		if (arg2=="U") U_string=arg1
		if (arg2=="B") B_string=arg1
		if (arg2=="V") V_string=arg1
		if (arg2=="R") R_string=arg1
		if (arg2=="I" || arg2=="i") I_string=arg1
		}
 	print(U_string//" "//B_string//" "//V_string//" "//R_string//" "//I_string)
	fd1=""
	################################ DISPLAY LIST OF AVAIABLE STANDARD FIELDS
	_field=field
	while (_field=="?") {
		printf("Reading standard catalog...%s \n", _stdcat)
		fd1=_stdcat
		if (fscan(fd1,id1,id2)!=EOF) act=id1
		n=1
		while (fscan(fd1, id1, id2)!=EOF) {
			if (id1==act) n=n+1
			else {
				printf('%15s with %3d standard stars.\n',act,n)
				n=1
				act=id1
				}
			}
		if (fscan(fd1,id1,id2)==EOF) {
				printf('%15s with %3d standard stars.\n',act,n)
				n=1
				act=id1
				}
		_field=field
		}
	
	############################## EXTRACT COORDINATES OF SELECTED STANDARD FIELD
	#fd1="wfpddb$standards.landolt"
	fd1=_stdcat
	find=no
	##### while(fscan(fd1,id1,id2,alp, dec_d, dec_m, dec_s, V)!=EOF) { OLD VERSION WITH STANDARDS.LANDOLT
	while(fscan(fd1,id1,id2,alp, dec, V)!=EOF) { 	
		if (id1!=_field) next
		find=yes
		#dec=dec_d//":"//dec_m//":"//dec_s
		#printf('%10s %10s ',alp, dec)
		#print (alp//" "//dec) | precess(startyea=2000,endyea=2000) | scan(alp, dec)
		#print (alp//" "//dec)
		print(alp//"  "//dec//"  "//id2//" "//V,  >>std)
	}
	
	if (!find) {
		print("Wrong standard field name")
		return
		}
	del(_result, ve+)
	while(fscan(imglist, img) !=EOF) {

	print("Measuring standard stars on image -> "//img)
	
	###### CHECK THE FILTER ID ON IMAGE

	hselect(img//"[0]", ins_filt, yes) | scan(filter)
	if (filter==U_string)  {
			print ("The filter is U ("//U_string//")")
			filter="U"
			}
	if (filter==B_string)  {
			print ("The filter is B ("//B_string//")")
			filter="B"
			}
	if (filter==V_string)  {
			print ("The filter is V ("//V_string//")")
			filter="V"
			}
	if (filter==R_string)  {
			print ("The filter is R ("//R_string//")")
			filter="R"
			}
	if (filter==I_string)  {
			print ("The filter is I ("//I_string//")")
			filter="I"
			}
	
	#### CHECK AND RECORD AIRMASS
	hselect(img//"[0]", key_airm, yes) | scan(airm)
	if (nscan()<1) {print("Warning! AIRMASS NOT PRESENT on image "//img)}	

	############################ DISPLAY IMAGE AND MARK STANDARD STARS
	if (disp) {
	print("Display....")
	#mscdisplay(img,1)
		}

	### IF CENTER, perform centering
	if (cnt) {
		del(coo_all, ve-, >>&errors)
		del(coo, ve-, >>&errors)
		copy(std, coo_all)
		copy(std, coo)
		del(coords, ve-,>>&errors)
		wfpcenter(img, coo, coords, columns="1,2", colmag="3", 
			inuni="hours", outuni="hours", astro-)
		del(coo, ve-)
		}
	else { 	del(coords,ve-,>>&errors)
		copy(std,coords)
		}
	if (!access(coords) && cnt) {
		print("Unable to perform centering: wrong standard field? Skipping image...")
		copy(std, coords)
		}
		
	
	if (disp) {
	#msctvmark(coords=coords, frame=1, wcs="world", mark="circle", radii=100, color=214, label+, nxoff=5, nyoff=5) 
		}
	############## PERFORM PHOTOMETRY
	
		
	## expand extensions
	imextensions(img, output="none", index="1-", extname="", extver="")
	n_ext=imextensions.nimages
	if (n_ext==0) n_ext=1
	print("FILTER: "//filter//"  N_EXT: "//n_ext//" IMAGE: "//img//"  FIELD: "//_field, >> _result)
	
	print("chip    ap         id    x       y      alpha       delta           mag      error  airmass", >> _result)
	first=yes
	for (j=1; j<=n_ext; j+=1) {
		if (n_ext==1) i=0 
		else i=j
		del("coords_"//i, ve-, >>&errors)
		mscctran(coords, "coords_"//i, img//"["//i//"]", inwcs="world",
			outwcs="logical", columns="1 2 3", units="hours deg", formats="",
			min_sig=9, ve-)		
		hselect(img//"["//i//"]", "naxis1 naxis2", yes) | scan (nc,nl)
		n=0
		del(stars, ve-, >>& errors)
		del(misu, ve-, >>&errors)
		fd1="coords_"//i
		while(fscan(fd1, x,y,id2)!=EOF) {
			if (x<1 || x>=nc || y<1 || y>= nl) next
			print(x//"    "//y//"    "//id2, >> stars)
			n=n+1
			}
		if (n==0) {
			print ("No standard stars on extension -> "//i)
			del("coords_"//i, ve-)
			next
			}
		if (disp) {	display(img//"["//i//"]",1)
				tvmark(1,coords=stars,mark="circle", radii=40, color=213,label+, nxoff=10,nyoffs=10)
			}
		if (first) {
			first=no
			}
			del(misu, ve-, >>&errors)
		del(transf, ve-, >>&errors)
		mscctran(stars, transf, img//"["//i//"]",inwcs="logical", outwcs="world", columns="1 2", units="",
			format="%.3H %.3h", min_sig=9, verbose-)
		del(tmpf, ve-, >>&errors)
		copy(stars, tmpf)
		del(stars, ve-)
		joinlines(list1=tmpf//","//transf, output=stars, delim=" ")
		#page(stars)
		#return
			del(output, ve-, >>&errors)
		datapars.exposur=key_exp
		print("Performing photometry on extension "//j//"....")
		phot(img//"["//i//"]", skyfile="none", output=output, coord=stars, intera-, verify-,verbo+, update+, >>misu)
		print("Done! Checking results....")
		#phot(img//"["//i//"]", skyfile="none", output="default", coord=stars, intera-, verify-,verbo+, update+)
			
	
		#page (output)
		fd1=output
		fd2=stars
		#page(coo_all)
		del(zero, ve-, >>&errors)
		
		#page(output)
		
		while(fscan(fd1,imname, x, y)!=EOF) {

			if(imname=="#" || imname=="#K" || imname=="#N" || imname=="#U" || imname=="#F") next
				if(fscan(fd1, tmp1,fd4)!=EOF) junk=""
				if(fscan(fd1, tmp1,fd4)!=EOF) junk=""
				if(fscan(fd1, tmp1,fd4)!=EOF) junk=""
				if(fscan(fd2, x,y,id2, _alp, _dec)!=EOF) junk=""
				while(fscan(fd1, ap, sum, area, flux, mag, magerr, pier, code) !=EOF) {
				#print (ap//"    "//imname)
				if(ap==imname) {
					if(fscan(fd2, x,y,id2, _alp, _dec)!=EOF) junk=""
				if(fscan(fd1, tmp1,fd4)!=EOF) junk=""
				if(fscan(fd1, tmp1,fd4)!=EOF) junk=""
				if(fscan(fd1, tmp1,fd4)!=EOF) junk=""
					next
						}

				if(code=="NoError" && mag!=INDEF) {
			
				#fd3=std
				#while(fscan(fd3, alp, dec, id2_2, V)!=EOF) {
				#	if(id2_2!=id2) {
				#			print("non e' quella giusta")
				#			next
				#			}
				#	magv=real(V)
				#	cterm=magv-mag
				#	printf('Star -> %10s Ap.: %4s Mag: %7.3f Real mag: %7s Zero: %7.3f \n',id2, ap,mag, V, cterm)
					mag=mag-25.0
					#print("Star: "//id2)
					printf('%2d %8s %10s %7.2f %7.2f %.3H %.3h %9.3f %7.3f %7.3f\n',
						j,ap, id2, x,y,_alp*15, _dec,mag, magerr,airm, >> _result)
					mag=mag+25.0	
				#print(cterm, >>zero)
				#			}
				#	fd3=""
						}
			else	{
				printf('Star -> %10s Ap.: %4s  not measured. CODE: %10s MAG: %10.3f \n', id2, ap, code, mag)
				} 

			}
			
			}
			

	del("coords_"//i, ve-)
	}
	#type (zero) | average | scan(zerom, sigma)	
	if (access(zero)) {
	 fd1=zero
	 n=0
	 meanz=0
	 #if (sigma<0.5) sigma=0.5
	 while(fscan(fd1, cterm)!=EOF) {
		if(abs(cterm-zerom)>(3*sigma)) next
		n=n+1
		meanz=meanz+cterm
		}
	 meanz=meanz/n
	 print("###### AVERAGE COLOR TERM AFTER 1 SIGMA REJECTION -> "//meanz)
	 print("###### USING A TOTAL OF "//n//" STANDARD STARS and APERTURES COMBINATIONS")
	}
	#else print("No star on current image")
	}
end


			

		
		
	