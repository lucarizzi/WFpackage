task license
include <fset.h>
procedure license()
char 	machine[SZ_LINE], user[SZ_LINE],pargstr(), output[150]
real	var[50], asumr(), sum, randomr(), mean, sigma, year_exp, month_exp, day_exp, date, data_expires, clgetr()
pointer open(), sp(), out
int 	ip1,ip2, strlen(), i, j

begin
	        call fseti(STDOUT,F_FLUSHNL,YES)
	call smark(sp)
	call clgstr("machine", machine, SZ_LINE)
	call clgstr("user", user, SZ_LINE)
	# reading expiration date
	year_exp = clgetr("year")
	month_exp = clgetr("month")
	day_exp = clgetr("day")


	call printf("Creating authorization for %s on %s\n")
	call pargstr(user)
	call pargstr(machine)
	out=open("wfpauthorize.dat", NEW_FILE, TEXT_FILE)
	# initialize
	do i=1,50 {
		var[i]=0.0
		}

	do i=1,strlen(user) {
		ip1=int(user[i])
		var[i-1]=((ip1-int(ip1/2))**(ip1/50))
		call printf("%s --> %3d --> %9.3f \n")
		call pargc(user[i])
		call pargi(ip1)
		call pargr(var[i-1])
		}
	do i=strlen(user)+1,strlen(user)+strlen(machine) {
		j=i-strlen(user)
		ip1=int(machine[j])
		var[i-1]=((ip1-int(ip1/2))**(ip1/50))
		call printf("%s  --> %3d --> %9.3f\n")
		call pargc(machine[j])
		call pargi(ip1)
		call pargr(var[i-1])
		}
	call aavgr(var, 50, mean, sigma)
	
	call amulkr(var, sigma, var, 50)
	sum=asumr(var, 50)

	call printf("%20d\n")
	call pargi(int(sum))
	call fprintf(out, "%20d\n")
	call pargi(int(sum))

	sum=sum/(mean*sigma)
	call adivkr(var, sum, var, 50)
	sum=asumr(var,50)

	# generating third code (date code)
	call printf("%20d\n")
	call pargr(year_exp)
	call printf("%20d\n")
	call pargr(month_exp)
	call printf("%20d\n")
	call pargr(day_exp)
	data_expires = year_exp*365 + month_exp * 30 + day_exp
	data_expires = data_expires*2-1

	call printf("%20d\n")
	call pargr(data_expires)

	call printf("%20d\n")
	call pargi(int(sum))
	call fprintf(out, "%20d\n")
	call pargi(int(sum))
	call fprintf(out, "%20.1f\n")
	call pargr(data_expires)
	# invert computation for check
	data_expires = (data_expires+1)/2
	year_exp = int(data_expires/365)
	month_exp = int((data_expires/365-year_exp)*12)
	day_exp = data_expires-year_exp*365-month_exp*30
	call printf("Expiration year  -> %20d\n")
	call pargr(year_exp)
	call printf("Expiration month -> %20d\n")
	call pargr(month_exp)
	call printf("Expiration day   -> %20d\n")
	call pargr(day_exp)

	call sfree(sp)
	#do i=1,150 {
	#	output[i]=char(int(randomr()))
	#	}
	call close(out)


end
