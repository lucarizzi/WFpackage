procedure wfpconvert(template, output)

string		template	{prompt="Template of coordinate files ?"}
string		output		{prompt="Output converted file ?"}
string		name		{prompt="Name of the new landold-like standard field?"}
struct		*fd1

begin
	
	int	wc, nl, wtot, id
	string 	tmpl, nam, str1, outf, alpha, delta
	file	tempo1, errors
	real	mag
	
	#### INPUT PARAMETER
	tmpl=template
	outf=output
	nam=name
	del(outf, ve+)

	tempo1=mktemp("tmp$iraf")
	errors=mktemp("tmp$errors")

	print("")
	print("Conversion from daofind results to Landolt-like files:")
	print("")
	
	print("Checking input files ")
	wtot=0
	for (i=1;i<=8;i=i+1) {
		if (access(tmpl//"_"//i)) {
			### il file esiste
			count(tmpl//"_"//i) | scan (wc)
			wc=wc-41
			printf("FILE: %s contains %6d stars \n",tmpl//"_"//i,wc)
			wtot=wtot+wc
			}
		else {
			print("WARNING! File "//tmpl//"_"//i//" does not exist!!!!")
			#print("ABORTING...")
			#return
			}
		}
	print("TOTAL: ---------------------------------------> "//wtot)
	print("Converting input files ")
	id=0
	for (i=1;i<=8;i=i+1) {
		if (access(tmpl//"_"//i)) {
			fd1=tmpl//"_"//i
			nl=0
			
			#### counting header lines
			while(fscan(fd1,str1)!=EOF) {
				nl=nl+1
				if (substr(str1,1,1)=="#") next
				break
				}
			nl=(nl-1)*(-1)

			#### removing header
			del(tempo1, ve-, >>&errors)
			tail(tmpl//"_"//i, nlines=nl, > tempo1)

			#### collecting measurements
			fd1=tempo1
			print("Adding stars from extension "//i)
			while(fscan(fd1, alpha, delta, mag)!=EOF) {
				printf("%15s %5d %s %s %.3f \n", nam, id, alpha, delta, mag, >> outf)
				id=id+1
				}
		}
		}
	id=id-1
	print(id//" stars converted and addded to output file")
	print("Bye.")

end

	

	