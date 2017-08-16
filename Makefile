.SUFFIXES: .4gl .42m 

.4gl.42m:
	fglcomp -M -W all $<

all:: catsource.42m fglscriptify.42m

fglscriptify: all catsource.bat catsource.sh catsource.4gl fglscriptify.4gl
	rm -f $@
	fglrun fglscriptify.42m -o $@ catsource.bat catsource.sh catsource.4gl fglscriptify.4gl

fglscriptify.bat: all catsource.bat catsource.sh catsource.4gl fglscriptify.4gl
	rm -f $@
	fglrun fglscriptify.42m -o $@ catsource.bat catsource.sh catsource.4gl fglscriptify.4gl

dist: fglscriptify fglscriptify.bat

clean:
	rm -f *.42?

distclean: clean
	rm -f fglscriptify fglscriptify.bat

