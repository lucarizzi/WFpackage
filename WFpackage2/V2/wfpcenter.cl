
procedure wfpdcenter(image, inname, outname)

file	image		{prompt="Image?"}
file	inname		{prompt="Name of the catalog?", mode="q"}
file    outname		{prompt="Name of output catalog?", mode="q"}
string	columns="2,3"	{prompt="Columns containing RA, DEC (col1, col2)?"}
string  colmag="0"	{prompt="Column containing magnitude (optional)"}
pset	centerpars	{prompt="Centering parameters ?"}
string	inunits="deg"	{prompt="RA units in input catalog ?", enum="deg|hours"}
string  outunits="deg"	{prompt="RA units in output catalog ?", enum="deg|hours"}
string  instr		{prompt="do not use, OBSOLETE "}
#bool	astro=no	{prompt="USE FOR astrometric solution (ONLY WFI@2.2) ?", mode="h"}
bool	astro=no	{prompt="Output in pixel (for astrom. solution, WFI@2.2 only) ?", mode="h"}


struct	*fd_1
struct  *fd_2
struct  *fd_3
begin

file	incat, outcat, incat_pixel, outcat_pixel, im
file	errors, tmptbl, list
int	i, nc, nl, n, n_ext
string	col, colma, code, inuni, outuni, format, mag, str1
real	 x,y,xc,yc, xerr, yerr, x1,y1, perc, lin1, lin2 
bool	mod, flag_ext
string  ins, testo 


	incat=inname
	outcat=outname
	im=image
	col=columns
	colma=colmag
	inuni=inunits
	outuni=outunits

	incat_pixel=mktemp("tmp$iraf")
	outcat_pixel=mktemp("tmp$iraf")
	errors=mktemp("tmp$iraf")
	tmptbl=mktemp("tmp$iraf")
	list=mktemp("tmp$iraf")

	mod=astro
################# SETUP PROCEDURE FOR SPECIFIED INSTRUMENT

        #ins = instr
#-EVH: get instrument from 'wfpsetup' par.s:
        ins = wfpsetup.instrument
        print("Using instrument table: "//ins)
        if (substr(ins, 1, 1)==" ") {
                print ("Did you run 'wfpsetup' to define the instrument ? ")
                return
        }


#
#################################################################################

	flag_ext = yes
	imextensions(im, output="none",index="1-", extname="", extver="")
	n_ext=imextensions.nimages
	if (n_ext==0) {
		flag_ext = no
		n_ext=1  ### COMPATIBILITY WITH 1 CCD
	}




########## TO REPEAT FOR EACH EXTENSION


# -------------------------------------------------------------- START MAIN LOOP ---
	for (j=1; j<=n_ext; j+=1) {




	if (n_ext==1) i=0 
	else i=j
	del(outcat//"_"//i, ve-, >>&errors)

######### CONVERT FROM WORLD TO PIXEL

	mscctran(incat, outcat//"_"//i,im//"["//i//"]", inwcs="world",
		outwcs="logical", columns=col, units=inuni//" deg", formats="",
		min_sig=9, ve-)
	#
	hselect(im//"["//i//"]", "naxis1 naxis2", yes) | scan(nc,nl)

######## SELECT ONLY THE STARS ON THE CURRENT EXTENSION
	n=0
	if(colma=="0") {
		fields(outcat//"_"//i, col, 
		lines="1-", quit-, print-, >>outcat//"_"//i//"_bis")
		del(outcat//"_"//i, ve-)
		fd_1=outcat//"_"//i//"_bis"
		page(outcat//"_"//i//"_bis")
		while(fscan(fd_1, x,y)!=EOF) {
			if (x<1 || x>=nc || y<1 || y>= nl) next
			#print(x//"                "//y, >> outcat//"_"//i)
			#print(x//"                "//y)
			printf("%.12f %.12f \n", x,y, >>outcat//"_"//i)
			n=n+1
			}
			}
	else {
	fields(outcat//"_"//i, col//","//colma, lines="1-", 
		quit-, print-, >>outcat//"_"//i//"_bis")
		del(outcat//"_"//i, ve-)
		fd_1=outcat//"_"//i//"_bis"
		while(fscan(fd_1, x,y, mag)!=EOF) {
			if (x<1 || x>=nc || y<1 || y>= nl) next
			#print(x//"                "//y//"   "//mag, >> outcat//"_"//i)
			#print(x//"                "//y//"   "//mag)
			printf("%.12f %.12f %30s\n", x,y,mag,>>outcat//"_"//i)
			n=n+1
		}
		#page(outcat//"_"//i)
		}

	
	del(outcat//"_"//i//"_bis", ve-)

	del(tmptbl, ve-, >>&errors)
	print("Centering stars on extension "//i)
	if (n==0) {
		print("No stars on extension "//i)
		next
		}
	n=0
	count(outcat//"_"//i) | scan(lin1)

	if (nscan() == 0) {
		print ("no star left")}
	else {
		print(lin1//" stars to center.")}

####### PERFORM CENTERING

 #-debug:  copy (outcat//"_"//i, "temp.dat")
	center(image=im//"["//i//"]", coords=outcat//"_"//i, 
		output=tmptbl, verbose+, verify-, intera-, >> outcat//"_"//i//"_center")

######del(tmptbl, ve-, >>&errors)


	fd_1=outcat//"_"//i//"_center"
	fd_2=outcat//"_"//i


	while(fscan(fd_1, str1, x1,y1,xc,yc, xerr, yerr, code)!=EOF) {
		if (str1 != im//"["//i//"]") next
		if(colma!="0")
			if(fscan(fd_2,x,y,mag)==EOF) next
		if(code=="ok")
			n=n+1
			if(colma!="0")
			print(xc//" "//yc//" "//mag, >> outcat//"_"//i//"_out")
			else
			print(xc//" "//yc, >>outcat//"_"//i//"_out")
	}


	if (n==0) {
		print("Centering failed on all stars on this extension.")
		del(outcat//"_"//i//"_center", ve-, >>&errors)
		del(outcat//"_"//i, ve-, >>&errors)
		copy(outcat//"_"//i//"_out",outcat//"_"//i)
		del(outcat//"_"//i//"_out", ve-, >>&errors)
		del(outcat//"_"//i//"_trans", ve-, >>&errors)
		next
		}

	count(outcat//"_"//i//"_out") | scan(lin2)
	perc=(1-(lin1-lin2)/lin1)*100
	printf("%4d stars centered: %.1f percent of the total.\n", lin2,perc)

	del(outcat//"_"//i//"_center", ve-, >>&errors)
	del(outcat//"_"//i, ve-, >>&errors)
	copy(outcat//"_"//i//"_out",outcat//"_"//i)
	del(outcat//"_"//i//"_out", ve-, >>&errors)
	del(outcat//"_"//i//"_trans", ve-, >>&errors)
	if(outuni=="hours") format="%.3H %.3h"
	else format="%.3h %.3h"



########## CONVERT FROM PIXEL TO SKY IF NOT ASTROSOLUTION
#- printing results for this extension in temp file. 

#- NORMAL CASE: output is RA, DEC:
	if (!mod) {
		mscctran(outcat//"_"//i, outcat//"_"//i//"_trans",  im//"["//i//"]",
			inwcs="logical", outwcs="world", columns="1 2", units="", 
			formats=format, min_sig=9, verbose-)
		}
#- ALTERNATE CASE, output is x,y in pixels:
#  (used for astrometric purposes by "wfpastro")
	else {
		fd_1=outcat//"_"//i
		while(fscan(fd_1,xc,yc,mag)!=EOF) {
		printf("%3d %10.2f %10.2f %30s \n", i, xc, yc, mag, >>outcat//"_"//i//"_trans")
		}
	}

	del(outcat//"_"//i, ve-, >>&errors)
#- write temp-file name in "list":
	print(outcat//"_"//i//"_trans", >> list)


	
	}
# ----------------------------------------------------------------- END MAIN LOOP ---



	if (access(list)) {count(list) | scan(n)} 
	else {n=0}

#- 
	if (n!=0) {
		fd_1=list
		del(outcat, ve-, >>&errors)
		while(fscan(fd_1, str1) !=EOF) {
			type(str1, >>outcat)
			del(str1, ve-)
		}
		

	count(outcat) | scan (lin1)
		}
	else {
		lin1=0
		}
	print("Done! *****************************")
	print("A total of "//lin1//" stars were centered.")	
		
	del(incat_pixel, ve-, >>&errors)
	del(outcat_pixel, ve-, >>&errors)
	del(tmptbl, ve-, >>&errors)
	del(list, ve-, >>&errors)
	del(errors, ve-)

end
