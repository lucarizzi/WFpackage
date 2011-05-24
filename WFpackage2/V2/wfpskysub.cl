
procedure wfpskysub(images)

file		images		{prompt="Mosaic images to be fit or background-subtracted", filetype="x"}
file		output		{prompt="Output images", filetype="x"}
string		type_output="residual"	{prompt="Type of output (fit,residual,response,clean)",enum="fit|residual|response|clean"}
string		list = "all"	{prompt="Extension number to be fit or background-subtracted, or all)"}
string		regions="mask"  {prompt="Good regions to fit (all,rows,columns,border,sections,circle,invcircle,mask)"}
string		mask="!BPM"	{prompt="Mask MEF file name or !keyword"}
int		xorder=3	{prompt="Order of function in x"}
int		yorder=3	{prompt="Order of function in y"}
pset		mscskysub	{prompt ="Edit full parameter set for mscskysub"}

string		mode="ql"	{prompt = "mode"}

struct		*imglist



begin

	string 		lst, typout, reg, msk
	string 		im, imfit, outima
	int		i, j, n_ext, extn, xord, yord
	file		imgfile, outp

	lst=list
	typout=type_output
	xord=xorder
	yord=yorder
	reg=regions
	msk=mask
	outp=output
	outima="dummy"

#-- EXPAND IMAGE LIST
	imgfile=mktemp("tmp$zero")
	sections (images, option="fullname", > imgfile)

#-- BEGIN OPERATIONS TO BE DONE FOR EACH IMAGE
	imglist = imgfile
	while (fscan(imglist, im) != EOF) {

		print("* Processing image: "//im)
		imextensions(im, output="none", index="1-", extname="", extver="")
		n_ext=imextensions.nimages 
	extn=INDEF

	if (lst!="all") {extn=int(lst)}

	if (n_ext==0) n_ext=1
	for (j=1; j<=n_ext; j+=1) {
		if (n_ext==1) i=0 
		else i=j
		if (lst!="all" && i!=extn) next

		imfit = im//"["//i//"]"
		print ("...hand over ",imfit," to mscskysub ...")
		imdel (outima, go+, veri-)
		mscskysub (imfit, output=outima, type_output=typout, xorder=xord, yorder=yord, regions=reg, mask=msk)
			print ("... overwriting ...")
			imcopy (outima, imfit, verb+)

	} #-- END FOR

}   #-- END WHILE
end
