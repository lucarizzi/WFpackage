procedure wfpzero (images)

file		images		{prompt="Mosaic images to be calibrated ?", filetype="x"}
file		names = "default"	{prompt="Names of the star catalogs, or 'default'"}
bool		header = yes	{prompt="Read catalog names from header keyword CATALOG ?"}
string		fields ="2,3,4"	{prompt="Columns containing alpha, delta, mag?"}
string		units = "deg"	{prompt="RA units in catalog ?", enum="hours|deg"}
real		magfaint = 16	{prompt="B magnitude of faintest star to use ?"}
#real		magzero = 25	{prompt="Magnitude zero point?"}
real		seeing = 5	{prompt="Seeing (in pixels) ?"}
int		exten = 2	{prompt="Operate on which extension?"}
real		initthresh = 20 {prompt="Initial star detection threshold ?"}
string		mod1 = "manual" {prompt="Mode?",enum="auto|manual|refine"}

bool            appl = yes      {prompt ="Apply correction to WCS? (for modes manual/auto)"}
bool		ref = yes       {prompt ="Refine shift determination (using msccmatch) ?"}

int		cbox = 11	{prompt ="msccmatch: Centering box (pixels)"}
real		maxshift = 4	{prompt ="msccmatch: Maximum centering shift to accept (arcsec) ?"}
real		cfrac = 0.5	{prompt ="msccmatch: Minimum fraction of accepted centers"}
pset		msccmatch	{prompt ="Edit full parameter set for msccmatch"}

bool            mosaic = yes    {prompt ="Apply global WCS adjustment to mosaic ?"}
string	instr = ""	{prompt = "Which instrument (DO NOT MODIFY) ?"}
file	wcs = "ASTROSOL_"	{prompt = "WCS database = astrometric solution", filetype="x"}

file		log = "wfpzero.log" {prompt = "Name of logfile?"}
file		error = "wfpzero.error" {prompt = "Name of errors file?"}

struct		*testo
struct		*imglist, *catlist


begin

	file	im, na, na_all, datab, cattemp, logf, na1, erf, logtmp
	real	ra, dec, num, ra_d, ra_h,dec_d, magb, magv, dist, pos, arg2
	real	ra_head, dec_head, in_num, sky, rms, sharp
        real     ra_x, dec_y, x, y, distmin, val, xmin, ymin,ra_h_ima, 
		dec_d_ima, see, xori, yori
        real    offs_ra, offs_dec, ra_h_min, dec_d_min, xshift,yshift, texp
	real	xc, yc, xdim, ydim, conv_def, ron_def, magze, maxsh, thresh, cfrc
	string	key_exp, key_conv, key_ron, key_air, key_filt, ins_file
        int     n, nmin, i, extn, nc, maxext, lines, starcat, starfil, fake, diff, nl, cbx
	string  str2, cod, arg1,modo, useless, imgfile, catfile, ins, wcssol1, wcssol2, wcssol
	string	fiel, uni, x_str, y_str, arg10,arg11, arg12
        bool    answ0, hea, check, single, err_det, mosa_global

	imgfile=mktemp("tmp$zero1")
	catfile=mktemp("tmp$zero")
	cattemp=mktemp("tmp$cat")
	logtmp=mktemp("tmp$logtmp")

	sections (images, option="fullname", > imgfile)
	sections (names, option="fullname", > catfile)
	count(catfile) | scan (lines)

	if (lines<2) single=yes 
	else single=no

	imglist = imgfile
	catlist = catfile

	fiel=fields
	#magze=magzero
	maxsh=maxshift
	cbx = cbox
	cfrc = cfrac
	uni=units
	logf=log
	thresh=initthresh

	mosa_global = mosaic
	if (!mosa_global) {
		print (" Individual CCD adjustment not yet implemented - assume global mosaic ")
		#print ("Using new option: individual CCD adjustment")
	}

################# SETUP ERROR LOGFILE
	erf=error
	time | scan(arg10,arg11, arg12)
	print(arg10, arg11, arg12, >> erf)
	err_det=no

	
	printf("\n\n\n %s\n","****************************** NEW RUN ******************************")
	printf("\n\n\n %s\n","****************************** NEW RUN ******************************", >> logf)

################# SETUP PROCEDURE FOR SPECIFIED INSTRUMENT

	#ins = instr
#-EVH: get instrument from 'wfpsetup' par.s:
	ins = wfpsetup.instrument
	print("Using instrument table: "//ins)
	print("Using instrument table: "//ins, >> logf)
	if (substr(ins, 1, 1)==" ") {
		print ("Did you run 'wfpsetup' to define the instrument ? ")
		return
	}

#-EVH: tried to get the database from 'wfpsetwcs' par.s:  NOW GO BACK TO LUCA's !
#-NO!	datab = wfpsetwcs.database
	datab = wcs

	print("Using WCS database: "//datab)
	print("Using WCS database: "//datab, >> logf)

	if (substr(datab, 1, 1)==" ") {
		print ("Did you edit 'wfpsetwcs' to write the WCS database ? ")
		return
	}


	if (!access(datab)) {
			print("WCS database not found ("//datab//")")
			datab = "wfpddb$"//datab
			if (access(datab)) {print ("ok, using ",datab)
			} else {return}
			    }

	#wfpsetup(instrument=ins)

############### VARIOUS OPTIONS CONCERNING CATALOGS
	check=yes
	hea = header
	while (fscan(imglist, im) != EOF) {
		err_det=no
		printf("\n\n\n %s\n","****************************** NEW IMAGE ******************************")
		printf("\n\n\n %s\n","****************************** NEW IMAGE ******************************", >> logf)
		print(arg10, arg11, arg12, >> logf)
		print("* Now calibrating image: "//im)
		print("********************************************")
		print("********************************************", >> logf)
		print("* Now calibrating image: "//im, >> logf)
		print("********************************************", >> logf)

############### DETERMINE THE NUMBER OF EXTENSIONS
		imextensions(im, output="none",index="1-", extname="", extver="")
		maxext=imextensions.nimages
		if (maxext==0) maxext=1  ### COMPATIBILITY WITH 1 CCD


	if (hea==yes) {
		hselect(im//"[0]", "CATALOG", yes) | scan (na)
			}
	else { if(!single) {
		if (check==yes) {
			 if(fscan(catlist, na) == EOF) 
					{ print("ERROR: No more catalogs available!")
					  return }
				}
			   }
		}# END /while (fscan(imglist/

	if (!access(na) && !(single)) { print("Catalog "//na//" does not exist. Exiting.")
				return
			}

	#######  IF THERE IS ONLY ONE CATALOG IN THE LIST, STOP CHECKING FOR CATALOG NAMES AFTER THE FIRST

	print ("single image ? ",single)
	print ("use header keyword ? ",hea)

	if(single && !(hea)) {

		if(fscan(catlist,na1)!=EOF) {

###			if (!access(na1))       {print("Specified catalog does not exist...",na1)
#- EVH:
			if (!access(na1) && na1 !="default")	{
				print("Specified catalog does not exist...",na1)
				return
								}
			else na=na1
					    }#fscan
		   }# END /if(single && !(hea))/


	#######  IF THE 'DEFAULT' OPTION IS SPECIFIED, BUILD THE CORRECT CATALOG NAME 	
	if((na=="default" && hea==no) || check==no)	{
			check=no
			nc=strlen(im)
			if (nc>5 && substr(im, nc-4, nc) == ".fits")
				im=substr (im,1,nc-5)
			else if (nc >4 && substr (im, nc-3, nc) == ".imh")
				im=substr (im,1, nc-4)
			na=im//".cat"
							}


		print("* using catalogue :"//na)
		print("********************************************")
		print("* using catalogue :"//na, >>logf)
		print("********************************************", >>logf)

	if(!access(na)) {print("The default catalog does not exist. Check with wfpcat!")
			return
			}







	### PROVA CON CCD INIZIALE E CAMBIAMENTO DI CCD
           extn=exten



	nl=0
#-------------------------------------------------- START BIG LOOP /nl<23/ ---
	while (nl<23) {
       





############### TRANSFORM IMAGE CENTER INTO SKY COORDINATE REMOVING WCSSOL

	na_all=na//"_all"
        modo=mod1

#-EVH: if 'REFINE' mode, then execute loop just once !
        if (modo=="refine") nl=24

	see=seeing
	del("tmptbl",ve-, >>& "errors")
	del("tmp_tr",ve-,>>& "errors" )
	hselect(im//"["//extn//"]", "NAXIS1,NAXIS2", yes) | scan (xdim, ydim)
	if (nscan()<2) {print("Warning: cannot determine image dimensions!")
			return}
	xc=xdim/2
	yc=ydim/2
	print(xc//" "//yc, > 'tmptbl')
	wcssol1=""
	hselect(im//"["//extn//"]", "WCSSOL", yes) | scan (wcssol1, wcssol2)
	if (wcssol1!="") {
		hedit(im//"["//extn//"]", "WCSSOL", add-, del+, upd+, ve-, show-)
			}


#- EVH: for this extension, transform 'logical' center to 'world':
	mscctran("tmptbl","tmp_tr",im//"["//extn//"]","logical","world",columns="1 2", units="", formats="%.3H %.2h",verbose-)	

	testo="tmp_tr"
	while(fscan(testo,ra,dec) != EOF)	{
		ra=ra
		dec=dec
						}


############### ACCESS CATALOGS IN DIFFERENT FORMATS
	testo=na
        ra_h=0
        dec_d=0
        num=0
        n=1
	del(na//"_new", ve-, >>& "errors")
	del(cattemp, ve-, >>&"errors")
	fields(na, fields=fiel, lines="1-", > cattemp)

	testo=cattemp

	if (magfaint==INDEF ) {

	while(fscan(testo, ra_d, dec_d, magb) !=EOF)	{   ###
		if(nscan()<1) next
		if (uni=="deg")
			ra_h=ra_d/15
		else	ra_h=ra_d
		printf("%15.10f %15.7f %5d %7.3f \n",ra_h, dec_d,n,magb,  >> na//"_new")
		n=n+1 
							}
	lines=0
	count(na//"_new") | scan (lines)
	if (lines<1)	{
		print("Unable to access specified columns or bad alpha units")
		print("Unable to access specified columns or bad alpha units", >>logf)
		return
			}

	}# END /if (magfaint==INDEF/


	else {
		while(fscan(testo, ra_d, dec_d, magb) !=EOF)	{
		if(nscan()<1) next

		if(magb<magfaint)	{
		if (uni=="deg")
			ra_h=ra_d/15
		else	ra_h=ra_d
		printf("%15.10f %15.7f %5d %7.3f \n",ra_h, dec_d,n,magb,  >> na//"_new")
		n=n+1 			}

								}
	lines=0
	count(na//"_new") | scan (lines)
	if (lines<1) {
		print("Unable to access specified columns or bad alpha units")
		print("Unable to access specified columns or bad alpha units", >>logf)
		return
		}
	}# END /else/



                 del(na//"_pixel",ve-,>>& "errors")


############### TRANSFORM CATALOG FROM ALPHA, DELTA TO PIXELS

		mscctran(na//"_new",na//"_pixel",im//"["//extn//"]","world", "logical",columns="1 2 3 4",units="hours degrees",formats="",min_sig=15,verbose=no)

		if (wcssol1!=""){
		wcssol=wcssol1//" "//wcssol2
		nc=strlen(wcssol)
		if (substr(wcssol,1,1)=="\"") {
				wcssol=substr (wcssol,2,nc-1)
						}
		hedit(im//"["//extn//"]", "WCSSOL", wcssol, add+, upd+, ve-, show-)
				}

	        testo=na//"_pixel"
		n=1
	        del(na//"_pixel1", ve-,>>& "errors")
		select_int(xdim,ydim,na//"_pixel",na//"_pixel1")
	        del(na//"_pixel", ve-,>>& "errors")


	lines=0
	count(na//"_pixel1") | scan (lines)

	if (lines<1)	{
		print("The catalog does not contain stars on image "//im)
		print("Check the catalog and/or the alpha units.")
		print("The catalog does not contain stars on image "//im, >>logf)
		print("Check the catalog and/or the alpha units.", >>logf)
		return
			}
	copy(na//"_pixel1", na//"_pixel")






#------------------------------------------- START SECTION FOR 'MANUAL' MODE ---
############### MANUAL MODE
	if (modo=="manual") {



############### DISPLAY IMAGE
	        display(im//"["//extn//"]",1, fill+)
        
############### DISPLAY BLUE CIRCLES ON CATALOG STARS
	        tvmark(1,na//"_pixel",mark="circle",radii=50, color=216, label-, number-)
	        del("tmptbl",ve-,>>& "errors")
	        print("Select a circle and type >> x << then exit with >> q <<")
		
#- frame= added (Luca.Hilo.apr09)
		imexam(im//"["//extn//"]", wcs="logical", frame=1, keep-) | scan(ra_x, dec_y)
	#### a volte imexam si incasina. Non so che farci!!
		if (nscan()<2) {
			print("Warning: cannot access results from IMEXAM")
			print("A full reset of the Image Display and IRAF may be needed")
			#print("BUG REPORT: Giuseppe Altavilla. 5 Oct 2000")
			return
			}
		
###############	FIND THE IDENTIFIED STAR ON THE CATALOG
	        testo = na//"_pixel"
		n=1
	        distmin=1000000000

	        while(fscan(testo,x,y,n) != EOF){
	              dist=(x-ra_x)**2+(y-dec_y)**2
	              if (dist < distmin){
	                          distmin=dist
	                          xmin=x
	                          ymin=y
	                          nmin=n
	                          	 } 
						}
		
	        print("The catalogue contains a star at coordinates "//xmin//"   "//ymin)
		del(na//"_select",ve-,>>&"errors")
		print(xmin//"    "//ymin,>na//"_select")
	        tvmark(coor=na//"_select", fra=1, mark="circle",radii=50,color=214, label-, number-)

		del(na//"_select",ve-,>>&"errors")
	        print("Now identify the same star with >> a << and exit with >> q <<")
		del("tmptbl",ve-,>>&"errors")

#- frame= added (Luca.Hilo.apr09)
	        imexam(im//"["//extn//"]", wcs="world",xformat="h", frame=1, keep-,  > "tmptbl")
	        fields("tmptbl", fields="3,4", line="3", > na//"_select")
         

############### CALCULATE OFFSETS (using magnitude-selected sub-catalog)

	        testo=na//"_new"

	        while(fscan(testo, ra_h, dec_d, n) != EOF)	{
	               if (n==nmin) 		{
	                  printf ("The coordinates are           RA = %.2H  DEC = %.2h\n",ra_h*15,dec_d)
		          printf ("Selected stars catalog coordinates: RA = %.2H  DEC = %.2h\n",ra_h*15,dec_d, >>logf)
	                  ra_h_min=ra_h
	                  dec_d_min=dec_d	}
	         						}


	        testo=na//"_select"
	        while(fscan(testo, ra_h_ima, dec_d_ima) != EOF) 	{
		#printf ("While the WCS coordinates are RA = %.2H  DEC = %.2h\n", ra_h_ima, dec_d_ima)
		#printf ("While the WCS coordinates are RA = %.2H  DEC = %.2h\n", ra_h_ima, dec_d_ima, >>logf
		printf ("WCS star's coordinates on image: RA = %.2H  DEC = %.2h\n", ra_h_ima, dec_d_ima)
		printf ("WCS star's coordinates on image: RA = %.2H  DEC = %.2h\n", ra_h_ima, dec_d_ima, >>logf
		ra_h_ima=ra_h_ima/15
									}


	        del(na//"_select",ve-,>>& "errors")
	        offs_ra=(ra_h_min-ra_h_ima)*15*3600*abs(cos(dec_d_min/
			57.29577851))
	        offs_dec=(dec_d_min-dec_d_ima)*3600
		## set nl to 24 to exit the cicle of the 8 ccd in manual mode
		   nl=24

	}#- END /IF MANUAL/






#---------------------------------------------------- START CASE 'AUTO' ---
############### AUTOMATIC MODE
	if (modo=="auto") {





	if(magfaint==INDEF)	{
		print("WARNING: Cannot use INDEF magnitude in automatic mode")
		print("ABORT!")
		print("WARNING: Cannot use INDEF magnitude in automatic mode", >>logf)
		print("ABORT!", >>logf)
		return
				}
		

############### VERSIONE CON IL FIND ESTERNO.....
	lines=0
	while (lines<50 && thresh>3)	{

		printf("Trying with detection threshold -> %.2f \n",thresh)
		del("cata_"//im//"_"//extn, ve-, >>&"errors")
		wfpfind(im, list=extn, templat="cata_"//im, type="logical", seeing=see, thresh=thresh, instr=ins)
		count("cata_"//im//"_"//extn) | scan(lines)
		if (lines<50)	{
			print("WARNING! Too few stars detected! Lowering detection threshold....")
			thresh=thresh*2/3
				}

					}

	del(im//"_cat1",ve-,>>&"errors")
	copy("cata_"//im//"_"//extn,im//"_cat1")
	del("cata_"//im//"_"//extn, ve-) 


############## REJECT ALL INDEF sharpness
	print("Rejecting bad stars...")
	testo=im//"_cat1"
	del(im//"_cat2", ve-, >>&"errors")

	while(fscan(testo, x_str,y_str,magb,sharp)!=EOF){
		if(nscan()<1) next
		if(substr(x_str,1,1)=="#") next
		if(sharp==INDEF) next
		print(x_str//"  "//y_str//"   "//magb, >> im//"_cat2")
							}

	del(im//"_cat1", ve-, >>&"errors")
	copy(im//"_cat2", im//"_cat1")
	del(im//"_cat2", ve-, >>&"errors")	
		
	del(im//"_cat",ve-,>>& "errors")
	copy(im//"_cat1", im//"_cat")
	del(im//"_cat1", ve-)

#### SELECTING THE 50 BRIGHTEST STARS (in the image)

del(im//"_sort", ve-, >>&"errors")
sort(im//"_cat", column=3, reverse-, numeric+, >>im//"_sort")
del(im//"_cat",ve-,>>&"errors")
testo=im//"_sort"
n=1
while(fscan(testo, x,y,magb)!=EOF)	{
	print(x//"  "//y//"  "//magb, >> im//"_cat")
	n=n+1
	if(n>50) break
					}
del(im//"_sort", ve-)


	
######### OVERLAPPING (matching) OF CATALOGS....

	count(na//"_pixel") | scan (starcat)
	print("The catalog contains "//starcat//" stars.")
	print("The catalog contains "//starcat//" stars.", >> logf)
	count(im//"_cat")   | scan (starfil)
	print("The find algorithm found "//starfil//" stars.")
	print("The find algorithm found "//starfil//" stars.", >>logf)
	########################## CI SONO PIU' STELLE NEL CAMPO CHE NEL CATALOGO
        #### PROVO UNA DIMINUZIONE A 2/3 delle stelle del catalogo


	if (starfil>starcat) {
		#diff=int((starfil-starcat)*3/2)
		diff=starfil-starcat
		print("Eliminating "//diff//" stars from the finding results")
		print("Eliminating "//diff//" stars from the finding results", >>logf)
		### sort in magnitudine
		sort(im//"_cat", column=3, numeric+, reverse-, >>im//"_sort")
		### elimina stelle fino ad avere lo stesso numero
		del(im//"_cat", ve-, >>&"errors")
		n=1
		testo=im//"_sort"
		while(fscan(testo,x,y,magb)!=EOF)	{
			printf("%15.10f %15.7f %15.7f \n",x,y,magb,  >> im//"_cat")
			n=n+1
			if (n>starcat) break
							}
		del (im//"_sort", ve-)
		count(im//"_cat")   | scan (starfil)
		print("Now the finding results contain  "//starfil//" stars.")	
		print("Now the finding results contain  "//starfil//" stars.", >>logf)	

	}#- END /if (starfil>starcat)/


	###################### CI SONO PIU' STELLE NEL CATALOGO CHE NEL CAMPO
	if (starcat>starfil) {

		diff=starcat-starfil
		print("Eliminating "//diff//" stars from the star catalog")
		print("Eliminating "//diff//" stars from the star catalog", >>logf)
		### sort in magnitudine
		sort(na//"_pixel", column=4, numeric+, reverse-, >>na//"_sort")
		### elimina stelle fino ad avere lo stesso numero
		del(na//"_pixel", ve-, >>&"errors")
		n=1
		testo=na//"_sort"
		while(fscan(testo, x, y, fake, magb)!=EOF)	{
			printf("%5.2f %5.2f %5d %7.3f \n",x,y,fake,magb, >> na//"_pixel")
			n=n+1
			if(n>starfil) break
								}
		del (na//"_sort", ve-)
		count(na//"_pixel") | scan (starcat)
		print("Now the catalog contains "//starcat//" stars.")
		print("Now the catalog contains "//starcat//" stars.", >>logf)

	}#- END /if (starcat>starfil)/	
		



############### MATCHING COORDINATES
	xyxymatch.xmag=1
	xyxymatch.ymag=1
	xyxymatch.xrotati=0
	xyxymatch.yrotati=0
        xyxymatch.nreject=10
        xyxymatch.nmatch=30
	xyxymatch.ratio=10
	xyxymatch.interac=no
	xyxymatch.refpoint=""
	xyxymatch.xin=INDEF
	xyxymatch.yin=INDEF
	xyxymatch.xref=INDEF
	xyxymatch.yref=INDEF
	xyxymatch.xcol=1
	xyxymatch.ycol=2
	xyxymatch.xrcol=1
	xyxymatch.yrcol=2
	del("match",ve-,>>& "errors")
	print("Matching stars...")
	xyxymatch(input=na//"_pixel",reference=im//"_cat",xin=INDEF,yin=INDEF,xref=INDEF,yref=INDEF,output="match",toler=9,ve+, interact-, >> logf)
	!wc match
	#!more match
	del(im//"_cat",ve-,>>& "errors")
	count("match") | scan(nl)


	if (nl<23) {
		    #print("ERROR! Cannot determine shifts")
	            #return
		    extn=extn+1
		    print("WARNING! Unable to compute offsets in this ccd")
		    print("Trying with next one...")
		    if (extn>maxext)	{
				#print("ERROR! Cannot determine shifts")
				print("ERROR! Cannot determine shifts for image:"//im)
				print("ERROR! Cannot determine shifts for image:"//im, >> erf)
				print("ERROR! Cannot determine shifts for image:"//im, >> logf)
				del(na//"_pixel1",ve-,>>& "errors")
				del(na//"_pixel",ve-,>>& "errors")				
				del("errors", ve-)	
				del(na//"_new", ve-)
				err_det=yes
				break
		                #return
					}
		    }#- end /if nl<23/


		    ############## PROVA DI CAMBIAMENTO DI CCD
	            ############## RIPETERE FINO A QUI


# LR: questa parentesi chiude la prima parte dell'automatic mode. Va tolta
#     se si toglie il ciclo sui ccd

				   } 
#- EVH ----------------------------------------------------------- END CASE 'AUTO' ---






				  }
#-------------------------------------------------- END BIG LOOP /nl<23/ --- ?????????




# LR: anche questo riparte con l'automatic mode e va tolto in caso 
#     di rimozione del ciclo sui ccd



#------------------------------------------- START CASE 'AUTO' + 'NO_ERROR' ---
       if (modo=="auto" && !err_det) {


	del("data",ve-,>>& "errors")
	print("Determining shifts...")
	geomap.xmin=INDEF
	geomap.ymin=INDEF
	geomap.xmax=INDEF
	geomap.ymax=INDEF
	geomap.fitgeom="shift"
	geomap.xxorder=2
	geomap.xyorder=2
	geomap.yxorder=2
	geomap.yyorder=2
	geomap.xxterms="half"
	geomap.yxterms="half"
	geomap.reject=2

	geomap(input="match",database="data", xmin=INDEF,xmax=INDEF, ymin=INDEF, ymax=INDEF,interact-,ve+, >> logf)

	del("match",ve-,>>&"errors")
	testo="data"

	while(fscan(testo,arg1,arg2) != EOF)	{

		if (arg1=="xshift") {
                         print("Xshift -> ", arg2)
			 xshift=-arg2}

		if (arg1=="yshift") {
			 print("Yshift -> ", arg2)
			 yshift=arg2}

		if (arg1=="xrms") {print("X_rms -> ",arg2)}
		if (arg1=="yrms") {print("Y_rms -> ",arg2)}
						}

	del("data",ve-,>>&"errors")
	del("tmptbl", ve-, >>&"errors")

        #print(xc//" "//yc, >>"tmptbl")
        print(xc,yc, >>"tmptbl")
	xc=xc+xshift
	yc=yc+yshift

        #print(xc//" "//yc, >>"tmptbl")
        print(xc,yc, >>"tmptbl")
	del("tmp_tr", ve-, >>&"errors")


#- convert to RA, DEC for this extension: 
	wcsctran("tmptbl", "tmp_tr", im//"["//extn//"]", "logical", "world", columns="1 2", units="", formats="%.3H %.2h", min_sig=9, verbose-)


	del("tmptbl", ve-, >>&"errors")

	offs_ra=0
#- NB. instrument file:
	ins_file="wfpddb$"//ins//".dat"

	testo=ins_file
	while(fscan(testo, arg1, arg2) != EOF)	{
		if (arg1=="x")   xori=real(arg2)
		if (arg1=="y")   yori=real(arg2)
						}

	testo="tmp_tr"
	while(fscan(testo, ra, dec) !=EOF)	{
		if(offs_ra==0)	{
			offs_ra=ra
			offs_dec=dec
				}
						}

	del("tmp_tr",ve-,>>&"errors")
	offs_ra=(offs_ra-ra)*xori*3600*15*abs(cos(dec/57.29577851))
	offs_dec=(offs_dec-dec)*yori*3600

	}
#--------------------------------------------------- END CASE 'AUTO' + 'NO_ERROR' ---





#- if no error, proceed with 'refine':

#------------------------------------------------------------ START CASE NO_ERROR ---
if (!err_det) {



#- refine, is requested, when modo=manual or auto: 
#----------------------------------- START CASE 'NOT_REFINE' ---
if (modo != "refine") {


		print("NO REFINE REQUESTED ...")
		print(modo//" "//err_det)
############### APPLY OFFSETS
	print("***********************************************")
	print("Offsets (Cat.star - measured)[proj.arcsec]: RA= "//offs_ra//"   DEC="//offs_dec)
	print("***********************************************")
	print("***********************************************", >>logf)
	print("Offsets (Cat.star - measured)[proj.arcsec]: RA= "//offs_ra//"   DEC="//offs_dec, >>logf)
	print("***********************************************",>>logf)

	#print("WARNING: If you answer yes to the following question")
	#print("I will apply the correction to the image WCS and write")
	#print("the corresponding shifts to the image header for future use")


		answ0 = appl
	        if(answ0==yes) {

		ra_head=0
		dec_head=0
		hselect (im//"[0]", "RA_offs", yes) | scan (ra_head)
		hselect (im//"[0]", "DEC_offs", yes) | scan (dec_head)
		if (nscan()<1) {
			print ("Writing offsets to image header...")
			print ("Writing offsets to image header...", >>logf)
				}
		else		{
			print ("Adding current offsets to previously determined shifts")
			print ("Adding current offsets to previously determined shifts", >>logf)
				}
		offs_ra=offs_ra+ra_head
		offs_dec=offs_dec+dec_head

		hedit (im//"[0]","RA_Offs", offs_ra, add+, del-, ve-, show+, update+, >>logf)
		hedit (im//"[0]","DEC_Offs", offs_dec, add+, del-, ve-, show+, update+, >>logf)

	####### THE WCSSOL KEYWORD IS DISABLED because mscctran DOES NOT SEEM TO WORK
		print("Applying wfpsetwcs with offsets: "//offs_ra//" "//offs_dec)

#- EVH: actually update WCS !
	        wfpsetwcs(images=im, database=datab, ra_offs=offs_ra,
		 dec_offs=offs_dec, wcssol-, reset-)

	        }# end /if(answ0==yes)/


	del("errors",ve-)
	del("tmptbl",ve-, >>& "errors")
	del("tmp_tr",ve-,>>& "errors" )
	del(na//"_pixel", ve-, >>&"errors")
	


############### REFINE SOLUTION (when mode is 'manual' or 'auto')
	#print("Do you want to refine the shift determination ")
	#print("using the whole star catalogue?")

	answ0 = ref
	print("The parameter refine is set to :"//answ0)
	print("The parameter refine is set to :"//answ0, >> logf)

	if (answ0==yes) {

		#print("Modify headers...")
		#for (i=1; i<=maxext; i+=1) {
		#hselect(im//"["//i//"]",key_air,yes) | scan (in_num)
		#hedit(im//"["//i//"]","AIRMASS",in_num, add+, update+, ve-)
		#hselect(im//"["//i//"]",key_filt,yes) | scan (in_num)
		#hedit(im//"["//i//"]","FILTER",in_num, add+, update+, ve-)
		#in_num=0
		#hselect(im//"["//i//"]",key_conv,yes) | scan (in_num)
		#if (in_num==0) {in_num=conv_def}
		#hedit(im//"["//i//"]","GAIN",in_num, add+, update+, ve-)
		#in_num=0
		#hselect(im//"["//i//"]", key_ron, yes) | scan (in_num)
		#if (in_num==0) {in_num=ron_def}
		#hedit(im//"["//i//"]","RDNOISE",ron_def, add+,update+,ve-)
	#} #-disabled by LR

		msccmatch.nfit=4
		msccmatch.rms=2
		msccmatch.maxshift=maxsh
		msccmatch.cbox=cbx
		msccmatch.cfrac=cfrc
		msccmatch.fitgeom="general"
#- verbose+  (Luca.Hilo.apr09)
		msccmatch.verb=yes

#- do it !
		msccmatch(input=im,coords=na//"_new",update+,inter-,fit-, > logtmp)

		#type (logtmp)
		#type (logtmp, >> logf)
		type (logtmp) | match (pattern=im, files="STDIN", stop+)
		type (logtmp) | match (pattern=im, files="STDIN", stop+) | type (>> logf)
	}#- end /if (answ0==yes)/

	del(na//"_pixel1",ve-,>>& "errors")
	del(na//"_pixel",ve-,>>& "errors")				
	del("errors", ve-)	
	del(na//"_new", ve-)


#---------------------------------------------------- END MODE 'not_refine' ---
	}



########################### REFINE MODE
#---------------------------------------------------- START 'REFINE' MODE  ---
	else {
			print("... starting REFINE MODE ...")

			msccmatch.nfit=4
			msccmatch.rms=2
			msccmatch.maxshift=maxsh
			msccmatch.cbox=cbx
			msccmatch.cfrac=cfrc
			msccmatch.fitgeom="general"
			msccmatch.verb=yes

			msccmatch(input=im,coords=na//"_new",update+,inter-,fit-, accept+, > logtmp)
			type (logtmp) | match (pattern=im, files="STDIN", stop+)
			type (logtmp) | match (pattern=im, files="STDIN", stop+) | type (>> logf)
			#type (logtmp, >> logf)

			del(na//"_pixel1",ve-,>>& "errors")
			del(na//"_pixel",ve-,>>& "errors")				
			del("errors", ve-)	
			#del(na//"_new", ve-)
		}
#---------------------------------------------------- END 'REFINE' MODE  ---
		




	}#- END /if (!err_det)/
#------------------------------------------------------------ END CASE NO_ERROR ---




	}
#------------------------------------------------------------ ????????????????????




#--------------------------------------  END --------------------------------------
end

#- EVH: check delete temp files (cattemp, tmp*, etc...)
