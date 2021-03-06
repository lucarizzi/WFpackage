
procedure wfpastro(image, inname, outname)

file	image		{prompt="Image?"}
file	inname		{prompt="Name of the input astrometry catalog?"}
file    outname		{prompt="Name of output database?"}
string  rauni		{prompt="RA keyword unit ?", enum="deg|hours"}
string	columns="2,3"	{prompt="Columns containing alpha and delta (col1, col2)?"}
string  inunits="deg"   {prompt="Input alpha units in astrometry catalog ?", enum="deg|hours"}
string  colid="1"	{prompt="Column containing star_id ?"}
bool	interactive=yes {prompt="Interactive fitting ?"}
real	reject=2	{prompt="Sigma clipping ?"}

pset    ccmap		{prompt="ccmap: other fitting options..."}

bool	keep=no		{prompt="Keep catalog of matched stars ?"}
file	catname	=""	{prompt="Root name for the catalog of matched star"}
string  instr ="wfi2p2"  	{prompt="Which instrument ? (DO NOT MODIFY)"}

struct	*fd_1
struct  *fd_2
struct  *fd_3



begin

file	incat, outdb, cent, cat, match, im, errors, catna, name
int	j, n_ext, i, ccd, k
string	id, id_c, col, coli, inuni, ins, _rauni
real	x_c, y_c, x, y, ra, dec, sig
bool	inte, kep


	incat=inname
	outdb=outname
	_rauni=rauni
	im=image
	col=columns
	inuni=inunits
	coli=colid
	inte=interactive
	sig=reject
	kep=keep
	catna=catname

	#ins = instr
#-EVH: get instrument from 'wfpsetup' par.s:
	ins = wfpsetup.instrument
	print("Using instrument table: "//ins)
	if (substr(ins, 1, 1)==" ") {
		print ("Did you run 'wfpsetup' to define the instrument ? ")
		return
	}


	cent=mktemp("tmp$center")
	cat=mktemp("tmp$cata")
	match=mktemp("tmp$match")
	errors=mktemp("tmp$errors")




	print("************************")
	print("*IMAGE= "//im)
	print("************************")

#- EVH: WARNING: fails if RA, DEC twice in header
	hselect (im//"[0]", "RA", yes) | scan (ra)
	hselect (im//"[0]", "DEC", yes) | scan (dec)	

	print("RA:"//ra//" DEC:"//dec)


###### PRODUCE CENTERED CATALOG

	wfpcenter(image=im, inname=incat, outname=cent, columns=col, 
		  colmag=coli, inunits=inuni,outuni="deg",astro+, instr=ins)
        #page(cent)
        #!sleep 10
####### SELECT USEFUL FIELDS FROM INPUT CATALOG

	fields(incat, fields=coli//","//col, lines="1-", >> cat)
        #page(cat)
######## EXPAND EXTENSIONS

	imextensions(im, output="none",index="1-", extname="", extver="")
	n_ext=imextensions.nimages
	if (n_ext==0) n_ext=1  ### COMPATIBILITY WITH 1 CCD



########## TO REPEAT FOR EACH EXTENSION

	for (j=1; j<=n_ext; j+=1) {


	if (n_ext==1) i=0 
	else i=j
	print("Matching stars on extension "//i)


#- scan lines in the catalog produced by wfpcenter:
	fd_1=cent
	while(fscan(fd_1, ccd, x, y, id)!=EOF) {
		if(ccd!=i) next
		fd_2=cat
#-              #- scan astrometry catalog; match star based on equal ID:
		while(fscan(fd_2, id_c, x_c, y_c)!=EOF) {
			if(id_c!=id) next

#- this is the correct line ! (Luca.Hilo.apr09)
			print(id//"  "//x//"  "//y//"  "//x_c//"  "//y_c, >>match)
			#wrong: print(id, x, y, x_c, y_c, >> match)

			break
			} # end_while
	} # end_while


####### BUILDING ASTROMETRIC SOLUTION FOR CURRENT CCD

	### INVERT THE ORDER ON THE BOTTOM ROW


#-----------------------------------------------------------------------------------------
#- EVH: WARNING: assume WFI@2.2  !!! 
	if (i<5) {k=i} 
	else {k=13-i}
#-----------------------------------------------------------------------------------------
	
	if (kep) {
		name=catna//"_ext"//i
		print("Storing matched stars on catalog "//name)
		del(name, ve-, >>&errors)
		copy(match, name)
	}


#-------------------------------------------------------------------------------------------
#- EVH: WARNING: must use "extname" instead of "solution" (see Valdes) [TBD]
#-------------------------------------------------------------------------------------------

#- uses RA, DEC  from image[0] as reference point:


#- EVH: for the WFI we used the following:
# 
# ccmap.xxorder = 4
# ccmap.xyorder = 4
# ccmap.xxterms = "full"
# ccmap.yxorder = 4
# ccmap.yyorder = 4
# ccmap.yxterms = "full"
# ccmap.maxiter = 0
# ccmap.pixsystem = "logical"


#- EVH: use RA, DEC in main_header as the ref_point:

	ccmap(input=match, database=outdb, solution="im"//k, images="", 
		xcol=2, ycol=3, lngcol=4, latcol=5, reject=sig,
		lngunits=inuni, latunits="deg", insys="j2000",
		refpoint="user", lngref=ra, latref=dec, refsyst="j2000", 
		lngrefuni=_rauni, latrefuni="deg",
		project="tnx", fitgeom="general",function="polynomial", 
		interactive=inte, upd-, ve+)

	#del(match, ve-, >>&errors)



	} # end_for 

end
