#we embed and image and xx.4gl in the script and pass also a custom imagepath
all: xx xx.bat

xx: xx.4gl
	rm -f xx
	../fglscriptify --env FGLIMAGEPATH=foo next.png xx.4gl

xx.bat: xx.4gl
	rm -f xx.bat
	../fglscriptify --env FGLIMAGEPATH=foo -o xx.bat next.png xx.4gl

clean:
	rm -f xx xx.bat

