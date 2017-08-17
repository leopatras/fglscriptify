#we embed and image and xx.4gl in the script and pass also a custom imagepath
all: xx xx.bat

xx: xx.4gl
	rm -f xx
	../fglscriptify next.png icons/smiley.png xx.per xx.4gl

xx.bat: xx.4gl
	rm -f xx.bat
	../fglscriptify -o xx.bat next.png icons/smiley.png xx.per xx.4gl

clean:
	rm -f xx xx.bat

