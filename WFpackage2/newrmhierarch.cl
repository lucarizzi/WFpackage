# RMHIERARCH - Translate HIERARCH keywords in a text file
# 
# The HIERARCH convention keywords are converted to simple FITS keywords in a
# text file.  Non-HIERARCH keywords are left alone.  For HIERARCH keywords it
# starts at a specified character and concatenates (removes whitespace) to
# the equal sign.  Then it truncates to 8 characters.  For example, with a
# value of 18 for the starting character the following translation would
# occur:
# 
#     "HIERARCH ESO INS FILT NAME" --> "FILTNAME"
#
# The default of 18 is good for the ESO HIERARCH keywords.
# 
# This task is commonly used with the task HFIX in a command such as:
# 
#     cl> hfix eso.fits command="rmhierarch $fname $fname"
# 
# When the input and output file names are the same the file is left modifed
# after translating the HIERARCH keywords.
# 
# To define this task, copy it to your home directory.  Then in your login.cl
# or loginuser.cl files or interactive enter:
# 
#     task rmhierarch = home$rmhierarch.cl



procedure rmhierarch (input, output)

file	input		{prompt="Input filename"}
file	output		{prompt="Output filename"}
int	start = 18	{prompt="Character to start at in HIEARCH keyword"}

struct	*fd

begin
	file	in, out, tmp
	string	key, value, key1
	struct	line
	int	idx
	bool 	check

	in = input
	out = output

	if (in == out)
	    tmp = mktemp ("tmp$iraf")
	else
	    tmp = out

	fd = in
	while (fscan (fd, line) != EOF) {
	    if (substr (line, 1, 8) != "HIERARCH") {
		printf ("%s\n", line, >> tmp)
		next
	    }
	    idx = stridx ("=", line)
	    if (idx <= start) {
		printf ("%s\n", line, >> tmp)
		next
	    }

	    key = substr (line, start, idx-1)


	    print (key) | translit ("STDIN", " ", delete+, collapse-) |
		scan (key)
	    value = substr (line, idx+2, strlen (line))
		check=yes
		printf("Found keyword :%s  ",key)

	key1=""
	print(key) | match(pattern="CHIP", files="STDIN", stop-) | scan (key1)
	if(strlen(key1)!=0) {print(key) | translit ("STDIN", "P",delete+, collapse-) | scan (key) }
	key1=""
	print(key) | match(pattern="PRSC", files="STDIN", stop-) | scan (key1)
	if(strlen(key1)!=0) {print(key) | translit ("STDIN", "C",delete+, collapse-) | scan (key) }
	key1=""
	print(key) | match(pattern="OVSC", files="STDIN", stop-) | scan (key1)
	if(strlen(key1)!=0) {print(key) | translit ("STDIN", "C",delete+, collapse-) | scan (key) }




		printf("Conversion: %-8.8s \n",key) 
	    printf ("%-8.8s= %s\n", key, value, >> tmp)
	}
	fd = ""

	if (in == out) {
	    delete (in, verify-)
	    rename (tmp, out, field="all")
	}
end
