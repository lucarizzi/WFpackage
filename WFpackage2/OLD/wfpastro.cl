procedure wfpastro(image, inname, outname)
file	image		{prompt="Image?"}
file	inname		{prompt="Name of the catalog?"}
file    outname		{prompt="Name of output database?"}
string  rauni		{prompt="RA keyword unit ?", enum="deg|hours"}
string	columns="3,4"	{prompt="Columns containing alpha and delta (col1, col2)?"}
string  inunits="deg"   {prompt="Input alpha units ?", enum="deg|hours"}
string  colid="1"	{prompt="Column containing star_id ?"}
bool	interactive=yes {prompt="Interactive fitting ?"}
real	reject=2	{prompt="Sigma clipping ?"}
pset    ccmap		{prompt="Other fitting options..."}
bool	keep=no		{prompt="Keep catalog of matched stars ?"}
file	catname		{prompt="Template for matched star catalog ?"}
string  instr ="wfi2p2"  	{prompt="Which instrument ?"}

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
	ins=instr
	kep=keep
	catna=catname
	inte=interactive

	cent=mktemp("tmp$center")
	cat=mktemp("tmp$cata")
	match=mktemp("tmp$match")
	errors=mktemp("tmp$errors")




	print("************************")
	print("*IMAGE= "//im)
	print("************************")

	hselect (im//"[0]", "RA", yes) | scan (ra)
	hselect (im//"[0]", "DEC", yes) | scan (dec)	

	print("RA:"//ra//" DEC:"//dec)

###### PRODUCE CENTERED CATALOG

	wfpcenter(image=im, inname=incat, outname=cent, columns=col, colmag=coli, inunits=inuni,outuni="deg",astro+, instr=ins)
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

	fd_1=cent
	while(fscan(fd_1, ccd, x, y, id)!=EOF) {
		if(ccd!=i) next
		fd_2=cat
		while(fscan(fd_2, id_c, x_c, y_c)!=EOF) {
			if(id_c!=id) next
			print(id//"  "//x//"  "//y//"  "//x_c//"  "//y_c, >>match)
			break
			}
	}

####### BUILDING ASTROMETRIC SOLUTION FOR CURRENT CCD
	### INVERT THE ORDER ON THE BOTTOM ROW
	if (i<5) {k=i} 
	else {k=13-i}
	
	if (kep) {
		name=catna//"_ext"//i
		print("Storing mathed stars on catalog "//name)
		del(name, ve-, >>&errors)
		copy(match, name)
	}


	ccmap(input=match, database=outdb, solution="im"//k, images="", 
		xcol=2, ycol=3, lngcol=4, latcol=5, reject=sig,
		lngunits=inuni, latunits="deg", insys="j2000",
		refpoint="user", lngref=ra, latref=dec, refsyst="j2000", lngrefuni=_rauni, latrefuni="deg",
		project="tnx", fitgeom="general",function="polynomial", 
		interactive=inte, upd-, ve+)
	del(match, ve-, >>&errors)


	}		

end


