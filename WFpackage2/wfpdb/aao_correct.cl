procedure aao_correct(images)

string	images {prompt="Images to be corrected "}
real	year   {prompt="Equinox of coordinates (1950, 2000) "}
struct  *fd1,*fd2

begin
	string imas,junk,filter
	file	imgfile,im, error
	real   rah,ram,ras,decd,decm,decs, ra, dec, yea
	int num, n_ext

	imgfile=mktemp("tmp$images")
	error=mktemp("tmp$error")

	imas=images
	yea=year
	if (!deftask("precess")) {astutil}
	sections (imas, option="fullname", > imgfile)

	fd1=imgfile
	while (fscan(fd1,im)!=EOF) {
		del("results", ve-, >>&error)
		del("tmp", ve-, >>&error)
		del("segno",ve-, >>&error)
		del("filter", ve-, >>&error)
		hselect(im//"[0]","RA,DEC",yes, >"results")
		!cat results | sed s/\"//g > tmp; mv tmp results
		!cat results | grep "-" > segno
		count("segno") | scan(num)
		
		fd2="results"
		while(fscan(fd2,rah,ram,ras,decd,decm,decs)!=EOF) {
			
			junk=""
		}
		del("results", ve-)
		ra=rah+ram/60+ras/3600
		dec=abs(decd)+decm/60+decs/3600
		if (num==1) {dec=-dec}
		print(ra//" "//dec, > "results")
		precess("results", yea, 2000) | scan(ra,dec)

		print(" -> "//ra//" "//dec)
		hselect(im//"[0]", "FILTER", yes, >"filter")
		!cat filter | awk '{print $1}' | sed s/\"//g > tmp; mv tmp filter
		fd2="filter"
		while(fscan(fd2,filter)!=EOF) {
			print(filter)
		}
	

	print ("Determining number of extensions ...")
		imextensions(im, output="none", index="1-", extname="", extver="")
		n_ext=imextensions.nimages 
	print ("Done. Image contains "//n_ext//" extensions")

	for (i=0;i<=n_ext;i=i+1) {
		print ("Updating extension "//i)
		hedit(im//"["//i//"]", "RA", ra, upd+, ve-, show+)
		hedit(im//"["//i//"]", "DEC", dec, upd+, ve-, show+)
		hedit(im//"["//i//"]", "FILTER", filter, upd+, ve-, show+)
		hedit(im//"["//i//"]", "EQUINOX", "2000.0", upd+, ve-, show+)
		print ("!!!!!! WARNING !!!!!!")
		print ("I AM REMOVING THE BSCALE and BZERO keywords")
		print ("because they conflict with iraf functionalities")
		print ("Please verify that the corresponding correction ")
		print ("has been applied at some stage...")
		hedit(im//"["//i//"]", "BSCALE,BZERO", del+, add-, upd+, ve-, show+) 
	}
	
	}
	del("results",ve-)
	del("segno",ve-)
	del(imgfile,ve-)
	del(error,ve-)
	del("filter", ve-)
end
