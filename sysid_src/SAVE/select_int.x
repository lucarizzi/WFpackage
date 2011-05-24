task select_int
include <fset.h>
procedure select_int()
real	xdim,ydim, var[50], mean, sigma, asumr()
real	x,y, clgetr(), fake, magb, sum1, sum2
char    infile[SZ_LINE], getline(), fscan(), outfile[SZ_LINE], id[SZ_LINE], machine[SZ_LINE], user[SZ_LINE],path[SZ_LINE], envgets()
pointer dati, line, open(), sp(), out, lic
int	ip1,ip2, strlen(), n, i, int, len, j
bool	leggo, streq(), legal, esiste, access()
double	dato1, dato2

begin
	call smark(sp)
	call fseti(STDOUT,F_FLUSHNL,YES)
	dato1=0
	dato2=0
	call printf("%15d\n")
	call pargd(dato1)
	#
	# riconoscimento sistema
	#
	#call sysid(id,SZ_LINE)
	#for (ip1=0; id[ip1] != '@'; ip1=ip1+1);
        #for (ip2=ip1; id[ip2] != ' '; ip2=ip2+1);
	#do i = ip1+1, ip2-1 {
        #        call strcat (id[i],system,ip2-1-ip1)}
	
	call gethost(id,SZ_LINE)
	do i=1,strlen(id) {
                #call strcat (id[i],system,ip2-1-ip1)
		call strcat (id[i], machine,strlen(id))
		}
	#call printf("HOST: %s\n")
	#call pargstr(machine)
	call getuid(id, SZ_LINE)
	do i=1,strlen(id) {
		call strcat (id[i], user,strlen(id))
		}
	#call printf("USER: %s\n")
	#call pargstr(user)



	legal=false
	#
	# lettura licenza
	#
	len=envgets("WFPRED_AUTH", path, SZ_FNAME)
	if (len==0) {
		call printf("Cannot access WFPRED_AUTH variable\n")
		call printf("User %s at %s cannot be authorized\n\n")
		call pargstr(user)
		call pargstr(machine)
		return}
	esiste = access (path, READ_ONLY, TEXT_FILE)
	if (!esiste) {  call printf("WARNING!! Cannot access authorization file\n")
			call printf("          This task will not work.\n")
			return
			}
	call printf("%15d\n")
	call pargd(dato1)
	lic=open(path, READ_ONLY, TEXT_FILE)
	line=fscan(lic)
	call gargd(dato1)
	call printf("%15d\n")
	call pargd(dato1)
	line=fscan(lic)
	call gargd(dato2)
	#
	# conti
	#
		do i=1,50 {
		var[i]=0.0
		}
		do i=1,strlen(user) {
			ip1=int(user[i])
			var[i-1]=((ip1-int(ip1/2))**(ip1/50))
			}
		do i=strlen(user)+1,strlen(user)+strlen(machine) {
			j=i-strlen(user)
			ip1=int(machine[j])
			var[i-1]=((ip1-int(ip1/2))**(ip1/50))
			}		
		call aavgr(var, 50, mean, sigma)
		call amulkr(var, sigma, var, 50)
		sum1=asumr(var, 50)
		
		sum2=sum1/(mean*sigma)
		call adivkr(var, sum2, var, 50)
		sum2=asumr(var,50)

		#call printf("%15d %15d %15d %15d\n")
		#call pargr(sum1)
		#call pargr(dato1)
		#call pargr(sum2)
		#call pargr(dato2)


	if (int(sum1)==int(dato1) && int(sum2)==(dato2)) {legal=true}

	if (legal) {
	
		call salloc(line,SZ_LINE,TY_CHAR)
		call clgstr ("infile", infile, SZ_FNAME)
		call clgstr ("outfile", outfile, SZ_FNAME)
		xdim = clgetr("xdim")
		ydim = clgetr("ydim")
		call printf("Dimensions: %9.3f %9.3f\n")
		call pargr(xdim)
		call pargr(ydim)
		dati = open (infile, READ_ONLY,TEXT_FILE)
		out = open (outfile, NEW_FILE, TEXT_FILE)
		n=1
		repeat {
		line = fscan(dati)
		call gargr(x)
		call gargr(y)
		call gargr(fake)
		call gargr(magb)
		if (line!=EOF) {
			#call printf("%9.3f %9.3f\n")
			#call pargr(out1)
			#call pargr(out2)
			if (x>0 && x<xdim && y>0 && y<ydim) {	
				call fprintf(out, "%5.2f %5.2f %5d %7.3f \n")
				call pargr(x)
				call pargr(y)
				call pargi(n)
				call pargr(magb)
				}
			n=n+1
			}
	
		}
		until (line==EOF) 
		call close(dati)
		call close(out)
		}
		call sfree(sp)	

	if (!legal) {
		call printf("$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!\n")
		call printf("System identification failed!\n")
		call printf("Check the license file and the variable WFPRED_AUTH \n")
		call printf("The package will not work on %s\n")
		call pargstr(machine)
		call printf("if you don't have the specific license file\n")
		call printf("$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!$!\n")
		}
	call close(lic)
end


