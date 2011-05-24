procedure wcsextract (image)
string	image	{prompt = "Image containing astrometric calibration ?"}
string  output  {prompt = "Output database ?"}
int	extnum  {prompt = "Number of extensions ?"}
int	sampx   {prompt = "Number of x sampling points ?"}
int     sampy   {prompt = "Number of y sampling points ?"}
string  unit    {prompt = "RA keyword unit (hours|degrees) ?", enum="hours|degrees"}

begin

	string _ima, _out, _uni, extname
	int    _num, first, nx, ny, xdim, ydim, ext
	real	x,y,xstep, ystep, ra, dec
	file	incoo, outcoo, errors, coordinates

	incoo = mktemp("tmp$incoo")
	outcoo = mktemp("tmp$outcoo")
	errors = mktemp("tmp$errors")
	coordinates = mktemp("tmp$coordinates")

	_ima = image
	_out = output
	_num = extnum
	_uni = unit

	if (access(_out)) {print("Warning! Database already exists...")
			   print("Exiting ...")
			   return
			 }

	nx=sampx
	ny=sampy

	if (_num==1) {first = 0; _num=0}
	else {first = 1}

	for (ext=first; ext<=_num; ext=ext+1) {

	print("Working on extension "//ext)
	extname = "noname"
	hselect(_ima//"["//ext//"]", "extname", yes) | scan (extname)
	if (nscan()==0) { print("Warning! Image does not contain extname")}

	print("Finding image center from header:")
	hselect(_ima//"["//ext//"]", "RA", "yes") | scan (ra)
	hselect(_ima//"["//ext//"]", "DEC", "yes") | scan (dec)
	if (_uni=="hours") {ra=ra*15}
	print("Field center and reference point:"//ra//" "//dec)
	
	
	print("Finding image dimension:")
	hselect(_ima//"["//ext//"]", "NAXIS1", "yes") | scan (xdim)
	hselect(_ima//"["//ext//"]", "NAXIS2", "yes") | scan (ydim)
	print("Image: "//_ima//"["//ext//"] is "//xdim//" x "//ydim)

	xstep = xdim/nx
	ystep = ydim/ny

	del(incoo, ve-, >>&errors)
	print("Building "//nx//" x "//ny//" grid...")
	for (x=1; x<xdim; x=x+xstep) {
		for (y=1; y<ydim; y=y+ystep) {
			print(x//" "//y, >> incoo)
		}
	}

	print("Transforming grid ...")
	del(outcoo, ve-, >>&errors)
	wcsctran(incoo, outcoo, _ima//"["//ext//"]", "logical", "world", 
		columns="1 2", units="", formats="", min_sig=15, verbose-)

        print("Computing database ...")
	del(coordinates, ve-, >>&errors)
	joinlines(incoo//","//outcoo, output=coordinates, verbose+)
	ccmap(coordinates, _out, solution=extname, images="", results="", 
		xcolumn=1, ycolumn=2, lngcolu=3, latcolu=4, 
		lngunit="deg", latunit="deg",
		refpoint="user",lngref=ra, latref=dec, lngrefu="deg", 
		latrefu="deg", project="tnx", update-)

	print("Done!")
	}			

	del(incoo, ve-, >>&errors)
	del(outcoo, ve-, >>&errors)
	del(coordinates, ve-, >>&errors)
	del(errors, ve-)

end


