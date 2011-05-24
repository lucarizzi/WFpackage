procedure wfpdcterm (photfile, apert)

file    photfile 	{prompt="File containing photometry ?"}
file	eqfile		{prompt="Output log file?", mode="q"}
real	apert=INDEF	{prompt="Aperture to use ?", mode="q"}
int	ccd		{prompt="CCD to calibate ?", mode="q"}
string	band		{prompt="Band ?", mode="q"}
string 	color		{prompt="Color ?", mode="q"}
int	deg=1		{prompt="Fitting order ?", mode="q"}
real	slope		{prompt="Fixed slope if used ?", mode="q"}
bool	again		{prompt="(y/n) ?", mode="q"}
struct	*fd1, *fd2, *fd3, *fd4, *fd5	

begin

file    _file, apch, errors, tbl, udata, bdata, vdata, rdata, idata, tbl1, eqf
file	ban, ref, stand, outfile, fit, outtbl, fields, act_phot, _now, colu
string	junk, chip, id, _ap, maxfile, now, maxap, id2, magstr, id1
string	field, ima1, ima2, fld, fld1, filt, id0
string  str1, str2, str3, str4, str5, str6, str7, str8, str9,str10
string 	_band, _color, mag1, mag2
real	ap, x,y,alp, dec, mag, _apert, dec1, dec2, dec3, mmag, mmagerr, mmagsqr,airm, slo
real 	u,b,v,r,i, magv, magbv,magub, magvr,magri, magvi, magu, magb, magr, magi
real	_u, _b, _v, _r, _i, c1, c2, c, rms, c1err, c2err, cserr
real	uerr, berr, verr, rerr, ierr,magerr, zero, cterm, x1,x2, y1,y2, cs, _err
real	ku,kb,kv,kr,ki, klambda
int	j, n_ext, lin, maxlin, k,_ccd, nl, _deg
bool	first, _again

#### READING  DATA
_file=photfile
eqf=eqfile
_apert=apert
apch=mktemp("tmp$apch")
errors=mktemp("tmp$errors")
_now=mktemp("tmp$_now")
tbl=mktemp("tmp$tbl")
tbl1=mktemp("tmp$tbl1")
udata=mktemp("tmp$udata")
bdata=mktemp("tmp$bdata")
outtbl=mktemp("tmp$outtbl")
vdata=mktemp("tmp$vdata")
rdata=mktemp("tmp$rdata")
idata=mktemp("tmp$idata")
ban=mktemp("tmp$ban")
ref=mktemp("tmp$ref")
fit=mktemp("tmp$fit")
stand=mktemp("tmp$stand")
outfile=mktemp("tmp$out")
fields=mktemp("tmp$fields")
act_phot=mktemp("tmp$phot")
colu=mktemp("tmp$colu")
_again=yes


#### AIRMASS SETUP
ku=0.50
kb=0.23
kv=0.12
kr=0.09
ki=0.02



### DETERMINATION OF OBSERVED FIELDS
fd1=_file
while(fscan(fd1,str1, str2, junk, j, ima1, ima2, fld, fld1)!=EOF) {
  if (str1!="FILTER:") next
	print(fld1, >> fields)
   }

#### RENDE UNICHE LE OCCURRENCES DEI FIELDS OSSERVATI
del(tbl, ve-, >>&errors)
sort(fields, >> tbl)
del(fields, ve-, >>&errors)
fd1=tbl
fld=""
while(fscan(fd1, fld1)!=EOF) {
    if (fld1!=fld) {
	print(fld1, >> fields)
	fld=fld1
	}
}


#### CHOSING APERTURE
## Fa un grafico che mostra le aperture se l'utente lascia INDEF


if (_apert==INDEF) {
first=yes
fd1=_file
del(apch, ve-, >>&errors)
while(fscan(fd1, str1, str2, junk, j, ima1, ima2, fld, fld1)!=EOF) {
	if (first) {
		 n_ext=j
		first=no
		#field=fld1
		print("Filter: "//str2)
		if(fscan(fd1, str1)!=EOF) junk=""
			}
	else print("Filter: "//_ap)
	while(fscan(fd1, chip, _ap, id, x, y, alp, dec, mag)!=EOF) {
		if(chip=="FILTER:") break
		print(_ap//" "//mag, >> apch)
		}
#### FIT 
	#print("qui ci passo")
	#page (apch)
	#!rm fit
	#copy (apch, fit)
        del(tbl, ve-, >>&errors)
	gfit1d(input=apch, output=tbl, function="spline1", order=1, intera+)
	#print("e anche qui")
	} 
	_apert=apert
	}
else {	fd1=_file
	if(fscan(fd1, str1, str2, junk, j, ima1, ima2, fld, fld1)!=EOF) n_ext=j
	#field=fld1
	fd1=""
	}
	print ("You chose aperture ",_apert)


#### OPERATIONS TO BE PERFORMED FOR EVERY OBSERVED FIELD:
fd3=fields
while(fscan(fd3,field)!=EOF) {
print("**************************************************")
print("***********  EXTRACTING DATA FOR FIELD: "//field)
print("**************************************************")
### DAL FILE CON LA FOTOMETRIA, PRENDE SOLO I LE LINEE CHE SI RIFERISCONO 
### AL CAMPO IN ESAME
del(act_phot, ve-, >>&errors)
fd1=_file
first=yes  
                #chip  ap    id    x     y     alpha delta mag   magerr
while(fscan(fd1, str1, str2, str3, str4, str5, str6, str7, str8, str9, str10) !=EOF) {
		if (str1=="FILTER:") {
			fld1=str8
			filt=str2
			first=yes
			next
			}
		if (str1=="chip") next
 		if (fld1==field) {
			if (first) {
			  first=no
			  print("FILTER: "//filt//" N_EXT: "//j//" IMAGE: "//ima2//" FIELD: "//fld1, >> act_phot)
			  print("chip    ap         id    x       y      alpha       delta        mag    error  airmass", >> act_phot)
			  }
			print(str1//" "// str2//" "// str3//" "// str4//" "// str5//" "// str6//" "// str7//" "// str8//" "// str9//" "// str10, >> act_phot)
			}
		}
#page(act_phot)
#return
	
 

### BUILD SUBSET OF STANDARD.LANDOLT
### dal file standard.landolt estrae solo le righe che si riferiscono al campo in esame

del(stand, ve-, >>&errors)
fd1="wfpddb$standards.landolt"
while(fscan(fd1, str1, str2, alp, dec1, dec2, dec3, magv, magbv, magub, magvr,
		magri, magvi)!=EOF) {
	if(str1!=field) next
	printf('%8s %10s %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f \n',
		str1, str2, magv, magbv, magub, magvr, magri, magvi, >>stand)
	}

	

### BUILD PHOTOMETRY FILE
for (k=1; k<=n_ext; k+=1) {

	if(n_ext>1) j=k 
	else j=k-1
	del(ban, ve-, >>&errors)
	del(udata, ve-, >>&errors)
	del(bdata, ve-, >>&errors)
	del(vdata, ve-, >>&errors)
	del(rdata, ve-, >>&errors)
	del(idata, ve-, >>&errors)
	print ("Collecting data for extension "//k)
	fd1=act_phot
	while(fscan(fd1, chip, _ap, id, x, y, alp, dec, mag, magerr, airm)!=EOF) {
		if(chip=="chip") next
	#### CERCA LA KEYWORD FILTER PER SAPERE DOVE ANDARE A SCRIVERE LE MAGNITUDINI
		if(chip=="FILTER:") {
			if (_ap=="U") {now=udata;klambda=ku}
			if (_ap=="B") {now=bdata;klambda=kb}
			if (_ap=="V") {now=vdata;klambda=kv}
			if (_ap=="R") {now=rdata;klambda=kr}
			if (_ap=="I") {now=idata;klambda=ki}
			
			print(now//"  "//_ap, >>ban)
			#print("Filter: "//_ap, >>now)
		
			next
		}			
       #### SE NON TROVA FILTER, E NON TROVA CHIP, SIGNIFICA CHE STIAMO LEGGENDO MISURE, 
       #### CONTROLLA CHE SI TRATTI DEL CCD GIUSTO
		if(int(chip)!=k) next
       #### CONTROLLA CHE SI TRATTI DELL'APERTURA GIUSTA
		if(real(_ap)!=_apert) next

	mag=mag-klambda*airm
	#print("Correggo con klambda = "//klambda//" e airmass "//airm)	
	print(id//"  "//mag//"  "//magerr, >> now)
	#print(id//"  "//mag//"  "//magerr)
	}

#page(bdata)
#return

#### ESEGUE LE OPERAZIONI DI MEDIA QUANDO UNA STELLA E' STATA OSSERVATA PIU' VOLTE.
if(access(ban)) {
	fd1=ban
	while(fscan(fd1, now)!=EOF) {
#		print("Current file:"//now)
#		page (now)
#		print("********************")
		if (access(now)) {
				count(now) | scan(lin)
				if (lin<2) next
				}
		if(access(now)) {
			del(tbl, ve-, >>&errors)
			del(tbl1, ve-, >>&errors)
			sort(now, >> tbl)
			fields(tbl, fields="1", lines="",>> tbl1)
			del(tbl, ve-)
			unique(tbl1, >> tbl)
			del(_now, ve-, >>&errors)
			copy(now, _now)
			del(now, ve-)
			fd4=tbl

			while(fscan(fd4, id0)!=EOF) {
				mmag=0;mmagerr=0;ct=0;mmagsqr=0
				fd5=_now
				while(fscan(fd5, id, mag, magerr)!=EOF) {
					if(id!=id0) next
					ct=ct+1
					mmag=mmag+mag	
					mmagerr=mmagerr+magerr # vecchia versione con l'errore dato dalla
								 # media degli errori
					}
				mmag=mmag/ct
				mmagerr=mmagerr/ct ## ancora la vecchia versione
				### NUOVA VERSIONE: CALCOLO DELLO SCARTO QUADRATICO MEDIO
				fd5=_now
				ct=0
				while(fscan(fd5, id, mag, magerr)!=EOF) {
					if(id!=id0) next
					ct=ct+1
					mmagsqr=mmagsqr+(mag-mmag)**2	
					}
				mmagsqr=sqrt(mmagsqr/ct)
#				print(id0//"  "//mmag//"  "//mmagerr//"  "//ct)
				if (mmagsqr>mmagerr) {mmagerr=mmagsqr}   ##### prende il massimo tra l'errore
									 #### formale e lo scarto quad.	
				print(id0//"  "//mmag//"  "//mmagerr, >> now)
			}
		
		#print("dopo la media:")
		#page(now)
		}
		}
		
				
	
		
	}

	#### TRA TUTTE LE BANDE A DISPOSIZIONE, SELEZIONA QUELLA CHE CONTIENE PIU' DATI
        #### PER USARLA COME RIFERIMENTO PER LA COSTRUZIONE DEL FILE DA PASSARE AL FIT

	fd1=""
	#page(ban)
	
	if(access(ban)) {
		fd1=ban
		maxlin=0
		while(fscan(fd1, now, _ap)!=EOF) {
		#page(now)
		if(access(now)) {
		count(now) | scan(lin)
		#print("Il file: "//now//" contiene "//lin//" righe")
		if(lin>maxlin) {
			maxfile=now
			maxap=_ap
			maxlin=lin
			}
			}
			}
#		if(maxlin!=1)	print("The reference filter is "//maxap)
#		else print("No data on extension "//k)
		if (maxlin==0) {print("********* Warning: No data on extension "//k);maxfile=""}

		}
	del(ref, ve-, >>&errors)
#print("qui ci passo")
	if (access(maxfile)) copy(maxfile, ref) ## NELLA VARIABILE REF C'E' IL NOME DEL FILE CHE CONTIENE PIU' MISURE (UBAND, VBAND...)
         

#### 	FA LA SCANSIONE DI QUESTO FILE TROVANDO GLI ID DELLE STELLE
####    POI CERCA TUTTI GLI ALTRI FILES PER TROVARE LO STESSO ID
fd1=ref
#if (access(ref)) print("il file ref esiste") 
#	else print("il file ref non esiste")
#page (ref)
if(access(ref)) {
    while(fscan(fd1, id, mag, magerr)!=EOF) {

	if(id=="Filter:") next
	if(access(udata)) {
		fd2=udata
		u=0
		uerr=0
		while(fscan(fd2, id2, magstr, _err)!=EOF) {
		if(id2=="Filter:") next
		if(id2!=id) next
		u=real(magstr)
		uerr=_err
		}
		}
	else 	{u=0 
		uerr=0}
	if(access(bdata)) {
		fd2=bdata
		b=0
		berr=0
		while(fscan(fd2, id2, magstr, _err)!=EOF) {
		if(id2=="Filter:") next
		if(id2!=id) next
		b=real(magstr)
		berr=_err
		}
		}
	else 	{b=0
		berr=0}
	if(access(vdata)) {
		fd2=vdata
		v=0
		verr=0
		while(fscan(fd2, id2, magstr,_err)!=EOF) {
		if(id2=="Filter:") next
		if(id2!=id) next
		v=real(magstr)
		verr=_err
		}
		}
	else 	{v=0
		verr=0}
	if(access(rdata)) {
		fd2=rdata
		r=0
		rerr=0
		while(fscan(fd2, id2, magstr,_err)!=EOF) {
		if(id2=="Filter:") next
		if(id2!=id) next
		r=real(magstr)
		rerr=_err
		}
		}
	else 	{r=0
		rerr=0}
	if(access(idata)) {
		fd2=idata
		i=0
		ierr=0
		while(fscan(fd2, id2, magstr,_err)!=EOF) {
		if(id2=="Filter:") next
		if(id2!=id) next
		i=real(magstr)
		ierr=_err
		}
		}
	else 	{i=0
		ierr=0	}
#print("e passo anche qui")
### SCRIVE LE MAGNITUDINI OSSERVATE, NELL'ORDINE U B V R I	

	printf('%2d %10s %7.3f %7.4f %7.3f %7.4f %7.3f %7.4f %7.3f %7.4f %7.3f %7.4f \n ',
		k,id,u,uerr,b,berr, v,verr,r,rerr, i,ierr, >>outfile)


### CERCA IL FILE DI STANDARD PER TROVARE LO STESSO ID E DA QUELLO DEDUCE LE MAGNITUDINI VERE

#	fd2=stand
#	while(fscan(fd2, id1, id2, magv, magbv, magub, magvr,magri, magvi)!=EOF) {
#		if(id2!=id) next
#		printf('%7.3f %7.3f %7.3f %7.3f %7.3f %7.3f \n',magv, 
#			magbv, magub, magvr,magri, magvi, >>outfile)
#	}

 #### IL FILE PER IL FIT E' PRONTO PER IL CCD CORRENTE
 #### SI PASSA AL SUCCESSIVO CCD

	fd2=""
	}

}

 #### IL FILE PER IL FIT E' PRONTO PER IL CCD CORRENTE
 #### SI PASSA AL SUCCESSIVO CCD	
	
	
}

 #### FINITI GLI 8 CCD

}  ### END of operations to be performed for every observed field
copy(outfile, eqf)

return
##### INIZIA A PREPARARE IL LOG FILE
print("ccd	filter	color  zerop             ct1              ct2              rms", >> eqf)

while(_again) {
####### SEARCH AVAIABLE CCDS
if(n_ext==0) print("Only one ccd to calibrate")
else {
		
print("This is the list of ccds to calibrate :")

for(j=1;j<=n_ext; j+=1) {
fd1=outfile
while(fscan(fd1, k)!=EOF) {
	if(k==j) {
		printf('%3d', k)
		break}
	}
}
printf('\n')
}
	
_ccd=ccd
print("You chose ccd ", _ccd)

#### CHECK AVAIABLE BANDS	
fd1=outfile
print("Avaiable bands :")
_u=0; _b=0; _v=0; _r=0; _i=0
while(fscan(fd1, j, id, u, uerr, b, berr, v, verr, r, rerr, i, ierr, 
	magv,magbv, magub, magvr,magri, magvi) !=EOF ) {
	
	if(j!=_ccd) next
	if(u!=0.0) _u=1
	if(b!=0.0) _b=1
	if(v!=0.0) _v=1
	if(r!=0.0) _r=1
	if(i!=0.0) _i=1
}

if (_u==1) printf('U ')
if (_b==1) printf('B ')
if (_v==1) printf('V ')
if (_r==1) printf('R ')
if (_i==1) printf('I ')
printf('\n')

####### CHOSE BAND AND COLOR
_band=band
_color=color
_deg=15
while(_deg!=1 && _deg!=2 && _deg!=0) {_deg=deg}

errorpars.errcolu="err"
errorpars.errtype="bars"
errorpars.resampl=yes
errorpars.sigma=INDEF
nfit1d.ltype="boxes"
if (_deg==0) { 	unlearn userpars
		userpars.function="c1+c2*x"
		slo=slope
		userpars.c1=24
		userpars.c2=slo
		userpars.v1=yes
		userpars.v2=no
		userpars.v3=no
		}
			

if(_deg==1) {	unlearn userpars
		userpars.function="c1+c2*x"
		userpars.c1=23
		userpars.c2=0.2
		userpars.v1=yes
		userpars.v2=yes
		userpars.v3=no
		}
if (_deg==2) {	unlearn userpars
		userpars.function="c1+c2*x+c3*x**2"
		userpars.c1=23
		userpars.c2=0.2
		userpars.c3=0.01
		userpars.v1=yes
		userpars.v2=yes
		userpars.v3=yes
		}
_u=0; _b=0; _v=0; _r=0; _i=0
if(_band=="U") _u=1
if(_band=="B") _b=1
if(_band=="V") _v=1
if(_band=="R") _r=1
if(_band=="I") _i=1
mag1=substr(_color,1,1)
mag2=substr(_color,2,2)
print("Computing "//_band//" versus  "//mag1//"-"//mag2//" for ccd number "//_ccd)
del(fit, ve-, >>&errors)
del(outtbl//".tab", ve-, >>&errors)
fd1=outfile
#page(outfile)
while(fscan(fd1, j, id, u, uerr, b, berr, v, verr, r, rerr, i, ierr, 
	magv, magbv, magub, magvr,magri, magvi) !=EOF ) {
	if(j!=_ccd) next
	magu=magv+magbv+magub
	magb=magv+magbv
	magr=magv-magvr	
	magi=magv-magvi
	if(mag1=="U") c1=magu
	if(mag1=="B") c1=magb
	if(mag1=="V") c1=magv
	if(mag1=="R") c1=magr
	if(mag1=="I") c1=magi
	if(mag2=="U") c2=magu
	if(mag2=="B") c2=magb
	if(mag2=="V") c2=magv
	if(mag2=="R") c2=magr
	if(mag2=="I") c2=magi
	c=c1-c2
	if (uerr<0.001) uerr=0.001
	if (berr<0.001) berr=0.001
	if (verr<0.001) verr=0.001
	if (rerr<0.001) rerr=0.001
	if (ierr<0.001) ierr=0.001
	

	if(_u==1 && u!=0.0) {u=magu-u
			printf('%.3f %.3f %.3f\n',c,u,uerr, >>fit)}
	if(_b==1 && b!=0.0) {b=magb-b
			printf('%.3f %.3f %.3f\n',c,b,berr, >>fit)}
	if(_v==1 && v!=0.0) {v=magv-v
			printf('%.3f %.3f %.3f\n',c,v,verr, >>fit)}
	if(_r==1 && r!=0.0) {r=magr-r
			printf('%.3f %.3f %.3f\n',c,r,rerr, >>fit)}
	if(_i==1 && i!=0.0) {i=magi-i
			printf('%.3f %.3f %.3f\n',c,i,ierr, >>fit)}

	}

count(fit) | scan(nl)
if(nl>2) {
	# TRASFORMA IL FILE FIT IN UNA TABLE PER AVERE CONTROLLO SUL 
	# DISPLAY
	del(colu, ve-, >>&errors)
	del(_band//".tab", ve-, >>&errors)
	print(_color//"  r", >> colu)
	print(_band//"  r", >> colu)
	print("err    r", >> colu)
	tcreate(table=_band, cdfile=colu, data=fit, upar="", nskip=0,
		nlines=0, nrows=0, hist=no, tbltype="default")
	tprint(_band//".tab")
	nfit1d(input=_band//" "//_color//" "//_band, output=outtbl, 
		function="user", intera+)
#	tprint(outtbl)	
#	tprint(outtbl)
	del(_band//".tab", ve-, >>&errors)
	tabpar(outtbl, "rms", 1)
	rms=real(tabpar.value)
	tabpar(outtbl, "coeff1", 1)
	zero=real(tabpar.value)
	tabpar(outtbl, "err1",1)
	c1err=real(tabpar.value)
	tabpar(outtbl, "coeff2", 1)
	cterm=real(tabpar.value)
	tabpar(outtbl, "err2",1)
	c2err=real(tabpar.value)
	if (_deg==2) {
		tabpar(outtbl, "coeff3", 1)
		cs=real(tabpar.value)
		tabpar(outtbl, "err3",1)
		cserr=real(tabpar.value)
		}

	}
if(nl==2) {	
	print("Warning: only 2 points!! NO FIT!!")
	fd1=fit
	if(fscan(fd1, x1,y1)!=EOF) junk=0
	if(fscan(fd1, x2,y2)!=EOF) junk=0
	id1=""
	cterm=(y2-y1)/(x2-x1)
	cs=0
	zero=y1-x1*cterm
	c1err=INDEF
	c2err=INDEF
	cserr=INDEF
	rms=INDEF
	}
if(nl==1) {print("Warning: only 1 point!! NO FIT!!")
	cterm=INDEF
	cs=INDEF
	zero=INDEF
	c1err=INDEF
	c2err=INDEF
	cs=INDEF
	cserr=INDEF
	rms=INDEF
	}
	print("Color equation: ")
	print("Filter: "//_band)
if (_deg==2) {
	print(zero//"  "//cterm//"*"//_color//"  "//cs//"*"//_color//"^2")
	printf('%2d      %s       %s     %6.3f +/-%6.3f %6.3f +/-%6.3f %6.3f +/-%6.3f %6.3f \n',
		_ccd, _band, _color, zero, c1err, cterm, c2err, cs, cserr, rms, >>eqf)
		}
if (_deg==1) {
	print(zero//"  "//cterm//"*"//_color)
	printf('%2d      %s       %s     %6.3f +/-%6.3f %6.3f +/-%6.3f                  %6.3f \n',
		_ccd, _band, _color, zero, c1err, cterm, c2err, rms, >>eqf)
		}
if (_deg==0) {
	print(zero//"  "//cterm//"*"//_color)
	printf('%2d      %s       %s     %6.3f +/-%6.3f %6.3f +/-%6.3f (fixed)          %6.3f \n',
		_ccd, _band, _color, zero, c1err, cterm, c2err, rms, >>eqf)	
		}
printf('Other calibration ')
_again=again
}
end

		







