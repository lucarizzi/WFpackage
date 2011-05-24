task ident_wfp
include <fset.h>
procedure ident_wfp()

int	ip1,ip2, len, i, strlen(), envgets(), j
char	id[SZ_LINE], machine[SZ_LINE], user[SZ_LINE],fscan()
real	path[SZ_LINE], var[50], asumr(), sum1, sum2, mean, sigma
pointer	line, open(), lic, sp()
bool	legal, esiste, access()
double	dato1, dato2

begin
	call smark(sp)
	call fseti(STDOUT,F_FLUSHNL,YES)
	call gethost(id,SZ_LINE)
        #for (ip1=0; id[ip1] != '@'; ip1=ip1+1);
        #for (ip2=ip1; id[ip2] != ' '; ip2=ip2+1);
        #do i = ip1+1, ip2-1 {
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
        len=envgets("WFPRED_AUTH", path, SZ_FNAME)
	if (len==0) {
		call printf("Cannot access WFPRED_AUTH variable\n")
		call printf("User %s at %s cannot be authorized\n\n")
		call pargstr(user)
		call pargstr(machine)
		return}
	esiste = access (path, READ_ONLY, TEXT_FILE)
	if (!esiste) {  call printf("WARNING!! Cannot access authorization file\n")
			call printf("          Some functions will not work.\n")
			return
			}
        lic=open(path, READ_ONLY, TEXT_FILE)
	legal=false
	dato1=0
	dato2=0
        line=fscan(lic)
        call gargd(dato1)
        line=fscan(lic)
        call gargd(dato2)
	call close(lic)
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

		call printf("%15d %15d %15d %15d\n")
		call pargr(sum1)
		call pargd(dato1)
		call pargr(sum2)
		call pargd(dato2)
		if (int(sum1)==int(dato1) && int(sum2)==(dato2)) {legal=true}
	if (legal) {
		call printf("User %s at %s is authorized.\n\n")
		call pargstr(user)
		call pargstr(machine)
		}
	if (!legal) {
		call printf("!!!!  Host %s is not authorized.\n")
		call pargstr(machine)
		call printf("!!!!  Please check your authorization file or \n")
		call printf("!!!!  request an authorized distribution\n")
		call printf("\n")
		}
	call sfree(sp)	

end
