procedure wfptnxsol(images)

string	images		{prompt="Images to work on ?"}
string  insol="esodb$wcs.db"		{prompt="Existing astrometric solution ?"}
pset	wfpzero		{prompt="!UPDATE WFPZERO (:e): magfaint, seeing, extn, initthresh"}
string	outsol		{prompt="Astrometric solution to be generated?"}
bool	subsets=yes	{prompt="Use only images with correct subset?"}
string	subimage	{prompt="Image containing the correct subset (and reference image) ?"}
bool	add=yes		{prompt="Add and center new solution?"}
bool	onecat=no	{prompt="Use only one reference catalog (no with std fields)?"}
string	instr		{prompt="Instrument (DO NOT MODIFY) ?"}
struct	*fd1, *fd2

begin

	string 	sol, subima, filter, img, filt_now, ins, arg1, flt_str
	file	imgfile, errors, refcat, in_sol
	string	na
	bool	subs, addsol, one
	string	old_lngref, old_latref, new_lngref, new_latref
	real	ra,dec, arg2
	int 	nc
	
	string  str1, str2

	errors=mktemp("tmp$errors")
	addsol=add
	one=onecat
	#### Check the subset paramater

	subs=subsets
	if (subs) {subima=subimage}
	in_sol=insol
	sol=outsol
	
	#### Expand the image list

	imgfile=mktemp("tmp$images")
	sections (images, option="fullname", > imgfile)
	

	#### IF REQUIRED, load the correct subset (filter)
	ins=instr
	ins="wfpddb$"//ins//".dat"
	fd1=ins
	while(fscan(fd1,arg1,arg2)!=EOF) {
		if (arg1=="KEYWORDS") break
		}
	while(fscan(fd1,arg1,str2)!=EOF) {	
		if (arg1=="filter") flt_str=str2
		}
	fd1=""

	if (subs) {
		hselect(subima//"[0]", flt_str, yes) | scan(filter)
		}	


	#### ON THE REFERENCE IMAGE, PERFORM CENTERING OF THE DEFAULT SOLUTION

	wfpzero(images=subima,names="", header+, fields="3,4,5", appl+,ref+,maxshift=4,wcs=in_sol, mod1="auto")
	wfpzero(images=subima,names="", header+, fields="3,4,5", appl+,ref+,maxshift=1,wcs=in_sol, mod1="ref")

	#### NOW,BUILD THE ASTROMETRIC SOLUTION FOR THIS IMAGE
		### REMOVE the .fits or .imh from the image name
		na=subima
		nc=strlen(subima)
		if (nc>5 && substr(subima, nc-4, nc) == ".fits")
		na=substr (subima,1,nc-5)
		else if (nc >4 && substr (subima, nc-3, nc) == ".imh")
		na=substr (subima,1, nc-4)
		if (access(sol)) {
			print("WARNING! The database solution ("//sol//") already exists.")
			print("Moving to "//sol//".OLD")
			!sleep 4
			del(sol//".OLD", ve-, >>&errors)
			rename(sol, sol//".OLD")
			}
		del(sol,ve-, >>&errors)
		wfpastro(subima,inname=na//".cat",outname=sol,columns="3,4", colid="1")

	#### ADD THE NEW SOLUTION TO THE REFERENCE IMAGE, REMOVING THE DEFAULT ONE
		wfpsetwcs(images=subima, database=sol, wcssol-, ra_offs=0, dec_offs=0, reset+)

	#### CENTER THE NEW SOLUTION
	#wfpzero(images=subima,names="", header+, fields="3,4,5", appl+,ref+,maxshift=4,wcs=sol, mod1="ref")	
	wfpzero(images=subima,names="", header+, fields="3,4,5", appl+,ref+,maxshift=1,wcs=sol, mod1="ref")	

	#### WHITH THE NEW SOLUTION, OBTAIN A CENTERED CATALOG (REFERENCE CATALOG) (IF REQUIRED)
	if (one) {wfpcenter(subima, inname=na//".cat", outname=na//".center.cat", columns="3,4", colmag="5", 
		inunits="deg", outunits="deg",astro-)
		  refcat=na//".center.cat"}
	#### CENTER THE SOLUTION ON THE REFERENCE IMAGE WITH THE REFERENCE CATALOG (IF REQUIRED)
	if (one) {wfpzero(images=subima,names=na//".center.cat", header-, fields="1,2,3", 
			appl+,ref+,maxshift=1,wcs=sol, mod1="ref")}
	
	### operations to be performed for each image
	fd1=imgfile
	while(fscan(fd1,img)!=EOF) {
		nc=strlen(img)
		if (nc>5 && substr(img, nc-4, nc) == ".fits")
		img=substr (img,1,nc-5)
		else if (nc >4 && substr (img, nc-3, nc) == ".imh")
		img=substr (img,1, nc-4)
		if(img==subima && one) next
		if (subs) {
			hselect(img//"[0]", flt_str, yes) | scan(filt_now)
			if (filt_now!=filter) {
				print("Image "//img//" rejected: "//filt_now//" is not "//filter)
				next
				}
			}
		### ADD THE NEW SOLUTION
		wfpsetwcs(img, database=sol, wcssol-, ra_offs=0, dec_offs=0, reset+)
		### CENTER THE NEW SOLUTION WITH THE DEFAULT CATALOG OR WITH THE REFERENCE CATALOG
	        	 ### REMOVE the .fits or .imh from the image name
		if (one) {wfpzero(images=img, names=refcat, header-, fields="1,2,3", mod1="auto", appl+,
				ref+, maxshift=4, wcs=sol)
			  wfpzero(images=img, names=refcat, header-, fields="1,2,3", mod1="ref", appl+,
				ref+, maxshift=1, wcs=sol)	}
		else {    wfpzero(images=img, names="", header+, fields="3,4,5", mod1="auto", appl+,
				ref+, maxshift=4, wcs=sol)
			  wfpzero(images=img, names="", header+, fields="3,4,5", mod1="ref", appl+,
				ref+, maxshift=1, wcs=sol)      }
		
	}
	
end






