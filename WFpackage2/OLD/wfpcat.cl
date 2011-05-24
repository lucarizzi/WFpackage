procedure wfpdcat (images, names)

string		images		{prompt="Mosaic image for catalogue generation?"}
file		names="default"	{prompt="Names of the catalogues?"}
int		maxob=1000	{prompt="Maximum number of objects?"}
real		radius=30	{prompt="Maximum search radius (arcmin)?"}
string		unit="hours"		{prompt="RA unit ?", enum="deg|hours"}
struct		*testo
struct		*imglist
struct		*catlist

begin
	file	 na, na_sort
	string	imgfile, im, catfile, str, id, uni, pippo
	real	rah, dech, r, b, d, pa
	int	lines, head, tail, max, nc, num, n
	bool	check, wait, fine
	real	rad, dec, ra

	max = maxob
	rad=radius
	catfile = mktemp("tmp$ctr")
	imgfile = mktemp ("tmp$ctr")
	na_sort = mktemp("tmp$sort")
	uni=unit

############### EXPAND IMAGE TEMPLATE and CATALOGUE LIST

	sections (images, option="fullname", > imgfile)
	section (names, option="fullname", > catfile)
	imglist = imgfile
	catlist = catfile
	check=yes

############### OPTIONS FOR CATALOG NAME GENERATION
	while (fscan(imglist, im) !=EOF ) {
		if (check==yes )
		if(fscan(catlist, na)==EOF) break

		if(na=="default" || check==no) {
			na=im
			check=no
			nc=strlen(im)
			if (nc>5 && substr(im, nc-4, nc) == ".fits")
				na=substr (im,1,nc-5)
			else if (nc >4 && substr (im, nc-3, nc) == ".imh")
				na=substr (im,1, nc-4)
			na=na//".cat"
			}

	print("************************")
	print("*IMAGE= "//im)
	print("************************")

	hselect (im//"[0]", "RA", yes) | scan (ra)
	hselect (im//"[0]", "DEC", yes) | scan (dec)	


############### SEARCH USNO CATALOG FOR STARS
	del("golynx", verify=no,>>& "errors")
	if (uni=="deg") {ra=ra/15}
	pippo = "%27"
	#print("lynx -dump \"http://archive.eso.org/skycat/servers/usnoa_res?catalogue=usnoa&epoch=2000.0&chart=0&ra="//ra//"&dec="//dec//"object=&radmax="//rad//"&magbright=0&magfaint=100&format=2&sort=mb%27&nout="//max//"\" > "//na, > 'golynx')
	printf("lynx -dump \"http://archive.eso.org/skycat/servers/usnoa_res?catalogue=usnoa&epoch=2000.0&chart=0&ra=%.7f&dec=%.7fobject=&radmax=%.2f&magbright=0&magfaint=100&format=2&sort=mb%s&nout=%d\" > %s\n", ra,dec,rad,, pippo, max,na, > 'golynx')
	#!cat golynx
	#return
	printf ("Searching USNO catalogue. Coordinates: RA = %.2H DEC = %.2h.\n",ra*15,dec)
	print ("Please wait....")
        !source golynx
	#!cat golynx
	#print("put the results in the file "//na)
	print ("Done!")
        del("golynx", ve-,>>& "errors")
	testo=na
	str=""
###### REMOVE THE "_"
	del(na//"_copy", ve-, >>&"errors")
	translit(na, "_", del=yes, >> na//"_copy")
	del(na, ve-)
	copy(na//"_copy", na)
	del(na//"_copy", ve-, >>&"errors")
		
	while(fscan(testo, str) !=EOF) {
		if (str=="nr") break
		
		}
	del(na//"_copy", ve-, >>&"errors")
	n=0
############### MODIFY CATALOG FORMAT
	print("Stripping useless lines...")
	while(fscan(testo, num, id, rah, dech, r, b, d, pa)!=EOF) {
		n=n+1
		if (n!=num) break
		else printf("%d %s %15.10f %15.7f %5.5f %5.5f %5.5f %5.5f \n", num, id, rah, dech, r, b, d, pa, >> na//"_copy")
				}
	n=n-1
	print("The catalog contains "//n//" stars")	
	testo=""		

	tail(na, nlines=1) | scan (num, id, rah, dech, r, b, d, pa)
	print("Magnitude of faintest stas B="//b)
	print("Updating header...")
	hedit(im//"[0]", "CATALOG", na, add+, del-, ver-, update+)
	print("Now you have file -> "//na//".")
	del(na, ve-, >>&"errors")
	copy(na//"_copy", na)
	del(na//"_copy", ve-)
	}
	del("errors", ve-)

end


