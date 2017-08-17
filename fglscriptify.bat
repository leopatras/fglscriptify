@echo off
@echo off
setlocal EnableExtensions

rem get unique file name 
:loop
set randbase=gen~%RANDOM%
set extractor="%tmp%\%randbase%.4gl"
set extractor42m="%tmp%\%randbase%.42m"
rem important: without quotes 
set _TMPDIR=%tmp%\%randbase%_d
set _IS_BAT_FILE=TRUE
if exist %extractor% goto :loop
if exist %extractor42m% goto :loop
if exist %_TMPDIR% goto :loop
rem echo tmp=%tmp%

set tmpdrive=%tmp:~0,2%
set _CATFILE=%~dpnx0
rem We use a small line extractor program in 4gl to a temp file
rem the bat only solutions at 
rem https://stackoverflow.com/questions/7954719/how-can-a-batch-script-do-the-equivalent-of-cat-eof
rem are too slow for bigger programs, so 4gl rules !

echo # Extractor coming from catsource.bat > %extractor%
echo --note: some 4gl constructs in this file are there to surround the pitfalls >> %extractor%
echo --of echo'ing this file with the windows echo command to a temp 4gl file >> %extractor%
echo --percent signs are avoided as well as or signs, thats why we avoid >> %extractor%
echo --the sfmt operator and the cat operator and mixing quotes with double quotes >> %extractor%
echo OPTIONS SHORT CIRCUIT >> %extractor%
echo IMPORT util >> %extractor%
echo IMPORT os >> %extractor%
echo DEFINE tmpdir,fname,full,lastmodule STRING >> %extractor%
echo DEFINE m_bat INT >> %extractor%
echo DEFINE singlequote,doublequote,backslash,percent,dollar STRING >> %extractor%
echo DEFINE m_binarr DYNAMIC ARRAY OF STRING >> %extractor%
echo DEFINE m_imgarr DYNAMIC ARRAY OF STRING >> %extractor%
echo MAIN >> %extractor%
echo   DEFINE line,err,catfile STRING >> %extractor%
echo   DEFINE ch,chw base.Channel >> %extractor%
echo   DEFINE sb base.StringBuffer >> %extractor%
echo   DEFINE write,writebin INT >> %extractor%
echo   LET singlequote=ASCII(39) >> %extractor%
echo   LET doublequote=ASCII(34) >> %extractor%
echo   LET backslash=ASCII(92) --we must not use the literal here >> %extractor%
echo   LET percent=ASCII(37) >> %extractor%
echo   LET dollar=ASCII(36) >> %extractor%
echo   LET m_binarr[m_binarr.getLength()+1]='png'  >> %extractor%
echo   LET m_binarr[m_binarr.getLength()+1]='jpg' >> %extractor%
echo   LET m_binarr[m_binarr.getLength()+1]='bmp' >> %extractor%
echo   LET m_binarr[m_binarr.getLength()+1]='gif' >> %extractor%
echo   LET m_binarr[m_binarr.getLength()+1]='tiff' >> %extractor%
echo   LET m_binarr[m_binarr.getLength()+1]='wav' >> %extractor%
echo   LET m_binarr[m_binarr.getLength()+1]='mp3' >> %extractor%
echo   LET m_binarr[m_binarr.getLength()+1]='aiff' >> %extractor%
echo   LET m_binarr[m_binarr.getLength()+1]='mpg' >> %extractor%
echo   LET sb=base.StringBuffer.create() >> %extractor%
echo   LET catfile=fgl_getenv("_CATFILE") --set by calling script >> %extractor%
echo   LET tmpdir=fgl_getenv("_TMPDIR") --set by calling script >> %extractor%
echo   LET m_bat=fgl_getenv("_IS_BAT_FILE") IS NOT NULL >> %extractor%
echo   IF catfile IS NULL OR tmpdir IS NULL THEN >> %extractor%
echo     CALL myerr("_CATFILE or _TMPDIR not set") >> %extractor%
echo   END IF >> %extractor%
echo   IF catfile IS NULL THEN >> %extractor%
echo     LET catfile=arg_val(1) >> %extractor%
echo     LET tmpdir=arg_val(2) >> %extractor%
echo   END IF >> %extractor%
echo   IF NOT m_bat THEN --windows fullPath is clumsy >> %extractor%
echo     LET tmpdir=os.Path.fullPath(tmpdir) >> %extractor%
echo   END IF >> %extractor%
echo   LET ch=base.Channel.create() >> %extractor%
echo   LET chw=base.Channel.create() >> %extractor%
echo   IF NOT os.Path.exists(tmpdir) THEN >> %extractor%
echo     IF NOT os.Path.mkdir(tmpdir) THEN >> %extractor%
echo       LET err="Can't mkdir :",tmpdir >> %extractor%
echo       CALL myerr(err) >> %extractor%
echo     END IF >> %extractor%
echo   END IF >> %extractor%
echo   CALL ch.openFile(catfile,"r") >> %extractor%
echo   WHILE (line:=ch.readLine()) IS NOT NULL >> %extractor%
echo     CASE >> %extractor%
echo        WHEN m_bat AND line.getIndexOf("rem __CAT_EOF_BEGIN__:",1)==1 >> %extractor%
echo          LET fname=line.subString(23,line.getLength()) >> %extractor%
echo          GOTO mark1 >> %extractor%
echo        WHEN (NOT m_bat) AND  line.getIndexOf("#__CAT_EOF_BEGIN__:",1)==1 >> %extractor%
echo          LET fname=line.subString(20,line.getLength()) >> %extractor%
echo        LABEL mark1: >> %extractor%
echo          LET full=os.Path.join(tmpdir,fname) >> %extractor%
echo          CALL checkSubdirs() >> %extractor%
echo          IF isBinary(fname) THEN >> %extractor%
echo            LET writebin=TRUE >> %extractor%
echo            CALL addImgDir(os.Path.dirName(fname)) >> %extractor%
echo            CALL sb.clear() >> %extractor%
echo          ELSE >> %extractor%
echo            LET write=TRUE >> %extractor%
echo            CALL chw.openFile(full,"w") >> %extractor%
echo          END IF >> %extractor%
echo        WHEN ((NOT m_bat) AND line=="#__CAT_EOF_END__") OR >> %extractor%
echo             (m_bat AND line=="rem __CAT_EOF_END__") >> %extractor%
echo          IF writebin THEN >> %extractor%
echo            LET writebin=FALSE >> %extractor%
echo            CALL util.Strings.base64Decode(sb.toString(),full) >> %extractor%
echo          ELSE >> %extractor%
echo            LET write=FALSE >> %extractor%
echo            CALL chw.close() >> %extractor%
echo            CALL eventuallyCompileFile() >> %extractor%
echo          END IF >> %extractor%
echo        WHEN writebin >> %extractor%
echo          CALL sb.append(line.subString(IIF(m_bat,5,2),line.getLength())) >> %extractor%
echo        WHEN write >> %extractor%
echo          CALL chw.writeLine(line.subString(IIF(m_bat,5,2),line.getLength())) >> %extractor%
echo     END CASE >> %extractor%
echo   END WHILE >> %extractor%
echo   CALL ch.close() >> %extractor%
echo   CALL runLastModule() >> %extractor%
echo END MAIN >> %extractor%
echo -- >> %extractor%
echo FUNCTION addImgDir(dirname) >> %extractor%
echo   DEFINE dirname STRING >> %extractor%
echo   DEFINE i INT >> %extractor%
echo   FOR i=1 TO m_imgarr.getLength() >> %extractor%
echo     IF m_imgarr[i]=dirname THEN >> %extractor%
echo       RETURN --already contained >> %extractor%
echo     END IF >> %extractor%
echo   END FOR >> %extractor%
echo   LET m_imgarr[m_imgarr.getLength()+1]=dirname >> %extractor%
echo END FUNCTION >> %extractor%
echo -- >> %extractor%
echo FUNCTION runLastModule() --we must get argument quoting right >> %extractor%
echo   DEFINE i INT >> %extractor%
echo   DEFINE arg,cmd STRING >> %extractor%
echo   IF lastmodule IS NULL THEN RETURN END IF >> %extractor%
echo   IF m_imgarr.getLength()>0 THEN >> %extractor%
echo     LET cmd=IIF(m_bat,"set FGLIMAGEPATH=","FGLIMAGEPATH=") >> %extractor%
echo     IF fgl_getenv("FGLIMAGEPATH") IS NOT NULL THEN >> %extractor%
echo       IF m_bat THEN >> %extractor%
echo         LET cmd=percent,"FGLIMAGEPATH",percent,";" >> %extractor%
echo       ELSE >> %extractor%
echo         LET cmd=dollar,"FGLIMAGEPATH:" >> %extractor%
echo       END IF >> %extractor%
echo     END IF >> %extractor%
echo     FOR i=1 TO m_imgarr.getLength() >> %extractor%
echo         IF i>1 THEN >> %extractor%
echo           LET cmd=cmd,IIF(m_bat,";",":") >> %extractor%
echo         END IF >> %extractor%
echo         LET cmd=cmd,os.Path.join(tmpdir,m_imgarr[i]) >> %extractor%
echo     END FOR >> %extractor%
echo     LET cmd=cmd,IIF(m_bat,"&&"," ") >> %extractor%
echo   END IF >> %extractor%
echo   LET cmd=cmd,"fglrun ",os.Path.join(tmpdir,lastmodule) >> %extractor%
echo   FOR i=1 TO num_args() >> %extractor%
echo     LET arg=arg_val(i) >> %extractor%
echo     CASE >> %extractor%
echo       WHEN m_bat AND arg.getIndexOf(' ',1)==0 AND  >> %extractor%
echo                      arg.getIndexOf(doublequote,1)==0 >> %extractor%
echo         LET cmd=cmd,' ',arg --we don't need quotes >> %extractor%
echo       WHEN m_bat OR arg.getIndexOf(singlequote,1)!=0  >> %extractor%
echo         --we must use double quotes on windows >> %extractor%
echo         LET cmd=cmd,' ',doublequote,quoteDouble(arg),doublequote >> %extractor%
echo       OTHERWISE >> %extractor%
echo         --sh: you can't quote single quotes inside single quotes >> %extractor%
echo         --everything else does not need to be quoted >> %extractor%
echo         LET cmd=cmd,' ',singlequote,arg,singlequote >> %extractor%
echo     END CASE >> %extractor%
echo   END FOR >> %extractor%
echo   --DISPLAY "cmd:",cmd >> %extractor%
echo   CALL myrun(cmd) >> %extractor%
echo END FUNCTION >> %extractor%
echo -- >> %extractor%
echo FUNCTION myerr(err) >> %extractor%
echo   DEFINE err STRING >> %extractor%
echo   DISPLAY "ERROR:",err >> %extractor%
echo   EXIT PROGRAM 1 >> %extractor%
echo END FUNCTION >> %extractor%
echo -- >> %extractor%
echo FUNCTION eventuallyCompileFile() >> %extractor%
echo   DEFINE cmd STRING >> %extractor%
echo   CASE >> %extractor%
echo     WHEN os.Path.extension(fname)=="4gl" >> %extractor%
echo       LET cmd="cd ",tmpdir," && fglcomp -M ",fname >> %extractor%
echo       CALL myrun(cmd) >> %extractor%
echo       --DISPLAY "dirname:",fname,",basename:",os.Path.baseName(fname) >> %extractor%
echo       LET lastmodule=os.Path.baseName(fname) >> %extractor%
echo       --cut extension >> %extractor%
echo       LET lastmodule=lastmodule.subString(1,lastmodule.getLength()-4) >> %extractor%
echo       --DISPLAY "lastmodule=",lastmodule >> %extractor%
echo     WHEN os.Path.extension(fname)=="per" >> %extractor%
echo       LET cmd="cd ",tmpdir," && fglform -M ",fname >> %extractor%
echo       CALL myrun(cmd) >> %extractor%
echo     --other (resource) files are just copied >> %extractor%
echo   END CASE >> %extractor%
echo END FUNCTION >> %extractor%
echo -- >> %extractor%
echo FUNCTION myrun(cmd) >> %extractor%
echo   DEFINE cmd STRING, code INT >> %extractor%
echo   --DISPLAY "myrun:",cmd >> %extractor%
echo   RUN cmd RETURNING code >> %extractor%
echo   IF code THEN >> %extractor%
echo     EXIT PROGRAM 1 >> %extractor%
echo   END IF >> %extractor%
echo END FUNCTION >> %extractor%
echo -- >> %extractor%
echo FUNCTION checkSubdirs() >> %extractor%
echo   DEFINE i,found INT >> %extractor%
echo   DEFINE dir,err STRING >> %extractor%
echo   DEFINE dirs DYNAMIC ARRAY OF STRING >> %extractor%
echo   IF m_bat THEN >> %extractor%
echo     RETURN  >> %extractor%
echo   END IF >> %extractor%
echo   LET dir=os.Path.fullPath(os.Path.dirName(full)) >> %extractor%
echo   WHILE TRUE >> %extractor%
echo     CASE >> %extractor%
echo       WHEN dir IS NULL >> %extractor%
echo         EXIT WHILE >> %extractor%
echo       WHEN dir==tmpdir >> %extractor%
echo         LET found=true >> %extractor%
echo         EXIT WHILE >> %extractor%
echo       OTHERWISE >> %extractor%
echo         CALL dirs.insertElement(1) >> %extractor%
echo         LET dirs[1]=dir >> %extractor%
echo     END CASE >> %extractor%
echo     LET dir=os.Path.fullPath(os.Path.dirName(dir)) >> %extractor%
echo   END WHILE >> %extractor%
echo   IF NOT found THEN >> %extractor%
echo     --we can't use sfmt because of .bat echo pitfalls >> %extractor%
echo     LET err=singlequote,fname,singlequote,' does point outside' >> %extractor%
echo     CALL myerr(err) >> %extractor%
echo   END IF >> %extractor%
echo   FOR i=1 TO dirs.getLength() >> %extractor%
echo     LET dir=dirs[i] >> %extractor%
echo     IF NOT os.Path.exists(dir) THEN >> %extractor%
echo       IF NOT os.Path.mkdir(dir) THEN >> %extractor%
echo         LET err="Can't create directory:",dir >> %extractor%
echo         CALL myerr(err) >> %extractor%
echo       END IF >> %extractor%
echo     END IF >> %extractor%
echo   END FOR >> %extractor%
echo END FUNCTION >> %extractor%
echo -- >> %extractor%
echo FUNCTION quoteDouble(s) >> %extractor%
echo   DEFINE s STRING >> %extractor%
echo   DEFINE c STRING >> %extractor%
echo   DEFINE i INT >> %extractor%
echo   DEFINE sb base.StringBuffer >> %extractor%
echo   LET sb=base.StringBuffer.create() >> %extractor%
echo   FOR i=1 TO s.getLength() >> %extractor%
echo     LET c=s.getCharAt(i) >> %extractor%
echo     CASE >> %extractor%
echo       WHEN c==doublequote >> %extractor%
echo         CALL sb.append(backslash) >> %extractor%
echo       WHEN (NOT m_bat) AND  c==backslash >> %extractor%
echo         CALL sb.append(backslash) >> %extractor%
echo     END CASE >> %extractor%
echo     CALL sb.append(c) >> %extractor%
echo   END FOR >> %extractor%
echo   RETURN sb.toString() >> %extractor%
echo END FUNCTION >> %extractor%
echo -- >> %extractor%
echo FUNCTION isBinary(fname) >> %extractor%
echo   DEFINE fname,ext STRING >> %extractor%
echo   DEFINE i INT >> %extractor%
echo   LET ext=os.Path.extension(fname) >> %extractor%
echo   FOR i=1 TO m_binarr.getLength() >> %extractor%
echo     IF m_binarr[i]==ext THEN  >> %extractor%
echo       RETURN TRUE >> %extractor%
echo     END IF >> %extractor%
echo   END FOR >> %extractor%
echo   RETURN FALSE >> %extractor%
echo END FUNCTION >> %extractor%
set mydir=%cd%
set mydrive=%~d0
%tmpdrive%
cd %tmp%
fglcomp -M %randbase%
if ERRORLEVEL 1 exit /b
del %extractor%
rem extract the 4gl code behind us to another 4GL file
%mydrive%
cd %mydir%
fglrun %extractor42m% %1 %2 %3 %4 %5
if ERRORLEVEL 1 exit /b
del %extractor42m%
exit /b
rem __CAT_EOF_BEGIN__:catsource.bat
rem @echo off
rem setlocal EnableExtensions
rem 
rem rem get unique file name 
rem :loop
rem set randbase=gen~%RANDOM%
rem set extractor="%tmp%\%randbase%.4gl"
rem set extractor42m="%tmp%\%randbase%.42m"
rem rem important: without quotes 
rem set _TMPDIR=%tmp%\%randbase%_d
rem set _IS_BAT_FILE=TRUE
rem if exist %extractor% goto :loop
rem if exist %extractor42m% goto :loop
rem if exist %_TMPDIR% goto :loop
rem rem echo tmp=%tmp%
rem 
rem set tmpdrive=%tmp:~0,2%
rem set _CATFILE=%~dpnx0
rem rem We use a small line extractor program in 4gl to a temp file
rem rem the bat only solutions at 
rem rem https://stackoverflow.com/questions/7954719/how-can-a-batch-script-do-the-equivalent-of-cat-eof
rem rem are too slow for bigger programs, so 4gl rules !
rem 
rem echo # Extractor coming from catsource.bat > %extractor%
rem rem HERE_COMES_CATSOURCE
rem set mydir=%cd%
rem set mydrive=%~d0
rem %tmpdrive%
rem cd %tmp%
rem fglcomp -M %randbase%
rem if ERRORLEVEL 1 exit /b
rem del %extractor%
rem rem extract the 4gl code behind us to another 4GL file
rem %mydrive%
rem cd %mydir%
rem fglrun %extractor42m% %1 %2 %3 %4 %5
rem if ERRORLEVEL 1 exit /b
rem del %extractor42m%
rem exit /b
rem __CAT_EOF_END__
rem __CAT_EOF_BEGIN__:catsource.sh
rem #!/bin/bash
rem DIR=`dirname "$0"`
rem #echo "DIR='$DIR'"
rem pushd "$DIR" >/dev/null
rem BINDIR=`pwd`
rem #echo "BINDIR='$BINDIR'"
rem popd > /dev/null
rem export _CATFILE="$BINDIR/`basename $0`"
rem export _CALLING_SCRIPT=`basename $0`
rem #echo "me:$_CATFILE"
rem firstcheck=`mktemp`
rem fglrun -V > $firstcheck
rem if [ $? -ne 0 ]
rem then
rem   rm -f $firstcheck
rem   echo "ERROR: no fglrun in the path"
rem   exit 1
rem fi
rem ver=`cat $firstcheck | sed -n '/Genero virtual machine/q;p'`
rem major=`echo $ver | sed -n 's/^.* \([0-9]*\)\.\([0-9]*\).*$/\1/p'`
rem rm -f $firstcheck
rem if [ $major -lt 3 ]
rem then
rem   echo "ERROR:fglrun version should be >= 3.0 ,current:$ver"
rem   exit 1
rem fi
rem 
rem replace_dot(){
rem # replace dot with underscore
rem   local dir=`dirname $1`
rem   local base=`basename $1`
rem #genero doesn't like dots in the filename
rem   base=`echo $base | sed -e 's/\./_/g'`
rem   echo "$dir/$base"
rem }
rem 
rem # compute a unique temp filename and a unique directory
rem # without dots in the name
rem while true
rem do
rem   _tmpfile=`mktemp`
rem   _tmpdir_extractor=`dirname $_tmpfile`
rem   rm -f $_tmpfile
rem   _tmpfile=`replace_dot $_tmpfile`
rem 
rem   _TMPDIR=`mktemp -d`
rem   rm -rf $_TMPDIR
rem   export _TMPDIR=`replace_dot $_TMPDIR`
rem 
rem   if [ ! -e $_tmpfile ] && [ ! -e $_TMPDIR ]
rem   then
rem     break
rem   fi
rem done
rem #echo "_tmpfile:$_tmpfile,_tmpdir_extractor:$_tmpdir_extractor,_TMPDIR:$_TMPDIR"
rem 
rem #we insert catsource.4gl on the next lines
rem cat >$_tmpfile.4gl <<EOF
rem #HERE_COMES_CATSOURCE
rem EOF
rem 
rem #now compile and run catsource from the temp location
rem pushd `pwd` > /dev/null
rem cd $_tmpdir_extractor
rem mybase=`basename $_tmpfile`
rem fglcomp -M $mybase.4gl
rem if [ $? -ne 0 ]
rem then
rem   exit 1
rem fi
rem rm -f $mybase.4gl
rem popd > /dev/null
rem fglrun $_tmpfile.42m "$@"
rem mycode=$?
rem rm -f $_tmpfile.42m
rem rm -rf $_TMPDIR
rem exit $mycode
rem __CAT_EOF_END__
rem __CAT_EOF_BEGIN__:catsource.4gl
rem --note: some 4gl constructs in this file are there to surround the pitfalls
rem --of echo'ing this file with the windows echo command to a temp 4gl file
rem --percent signs are avoided as well as or signs, thats why we avoid
rem --the sfmt operator and the cat operator and mixing quotes with double quotes
rem OPTIONS SHORT CIRCUIT
rem IMPORT util
rem IMPORT os
rem DEFINE tmpdir,fname,full,lastmodule STRING
rem DEFINE m_bat INT
rem DEFINE singlequote,doublequote,backslash,percent,dollar STRING
rem DEFINE m_binarr DYNAMIC ARRAY OF STRING
rem DEFINE m_imgarr DYNAMIC ARRAY OF STRING
rem MAIN
rem   DEFINE line,err,catfile STRING
rem   DEFINE ch,chw base.Channel
rem   DEFINE sb base.StringBuffer
rem   DEFINE write,writebin INT
rem   LET singlequote=ASCII(39)
rem   LET doublequote=ASCII(34)
rem   LET backslash=ASCII(92) --we must not use the literal here
rem   LET percent=ASCII(37)
rem   LET dollar=ASCII(36)
rem   LET m_binarr[m_binarr.getLength()+1]='png' 
rem   LET m_binarr[m_binarr.getLength()+1]='jpg'
rem   LET m_binarr[m_binarr.getLength()+1]='bmp'
rem   LET m_binarr[m_binarr.getLength()+1]='gif'
rem   LET m_binarr[m_binarr.getLength()+1]='tiff'
rem   LET m_binarr[m_binarr.getLength()+1]='wav'
rem   LET m_binarr[m_binarr.getLength()+1]='mp3'
rem   LET m_binarr[m_binarr.getLength()+1]='aiff'
rem   LET m_binarr[m_binarr.getLength()+1]='mpg'
rem   LET sb=base.StringBuffer.create()
rem   LET catfile=fgl_getenv("_CATFILE") --set by calling script
rem   LET tmpdir=fgl_getenv("_TMPDIR") --set by calling script
rem   LET m_bat=fgl_getenv("_IS_BAT_FILE") IS NOT NULL
rem   IF catfile IS NULL OR tmpdir IS NULL THEN
rem     CALL myerr("_CATFILE or _TMPDIR not set")
rem   END IF
rem   IF catfile IS NULL THEN
rem     LET catfile=arg_val(1)
rem     LET tmpdir=arg_val(2)
rem   END IF
rem   IF NOT m_bat THEN --windows fullPath is clumsy
rem     LET tmpdir=os.Path.fullPath(tmpdir)
rem   END IF
rem   LET ch=base.Channel.create()
rem   LET chw=base.Channel.create()
rem   IF NOT os.Path.exists(tmpdir) THEN
rem     IF NOT os.Path.mkdir(tmpdir) THEN
rem       LET err="Can't mkdir :",tmpdir
rem       CALL myerr(err)
rem     END IF
rem   END IF
rem   CALL ch.openFile(catfile,"r")
rem   WHILE (line:=ch.readLine()) IS NOT NULL
rem     CASE
rem        WHEN m_bat AND line.getIndexOf("rem __CAT_EOF_BEGIN__:",1)==1
rem          LET fname=line.subString(23,line.getLength())
rem          GOTO mark1
rem        WHEN (NOT m_bat) AND  line.getIndexOf("#__CAT_EOF_BEGIN__:",1)==1
rem          LET fname=line.subString(20,line.getLength())
rem        LABEL mark1:
rem          LET full=os.Path.join(tmpdir,fname)
rem          CALL checkSubdirs()
rem          IF isBinary(fname) THEN
rem            LET writebin=TRUE
rem            CALL addImgDir(os.Path.dirName(fname))
rem            CALL sb.clear()
rem          ELSE
rem            LET write=TRUE
rem            CALL chw.openFile(full,"w")
rem          END IF
rem        WHEN ((NOT m_bat) AND line=="#__CAT_EOF_END__") OR
rem             (m_bat AND line=="rem __CAT_EOF_END__")
rem          IF writebin THEN
rem            LET writebin=FALSE
rem            CALL util.Strings.base64Decode(sb.toString(),full)
rem          ELSE
rem            LET write=FALSE
rem            CALL chw.close()
rem            CALL eventuallyCompileFile()
rem          END IF
rem        WHEN writebin
rem          CALL sb.append(line.subString(IIF(m_bat,5,2),line.getLength()))
rem        WHEN write
rem          CALL chw.writeLine(line.subString(IIF(m_bat,5,2),line.getLength()))
rem     END CASE
rem   END WHILE
rem   CALL ch.close()
rem   CALL runLastModule()
rem END MAIN
rem 
rem FUNCTION addImgDir(dirname)
rem   DEFINE dirname STRING
rem   DEFINE i INT
rem   FOR i=1 TO m_imgarr.getLength()
rem     IF m_imgarr[i]=dirname THEN
rem       RETURN --already contained
rem     END IF
rem   END FOR
rem   LET m_imgarr[m_imgarr.getLength()+1]=dirname
rem END FUNCTION
rem 
rem FUNCTION runLastModule() --we must get argument quoting right
rem   DEFINE i INT
rem   DEFINE arg,cmd STRING
rem   IF lastmodule IS NULL THEN RETURN END IF
rem   IF m_imgarr.getLength()>0 THEN
rem     LET cmd=IIF(m_bat,"set FGLIMAGEPATH=","FGLIMAGEPATH=")
rem     IF fgl_getenv("FGLIMAGEPATH") IS NOT NULL THEN
rem       IF m_bat THEN
rem         LET cmd=percent,"FGLIMAGEPATH",percent,";"
rem       ELSE
rem         LET cmd=dollar,"FGLIMAGEPATH:"
rem       END IF
rem     END IF
rem     FOR i=1 TO m_imgarr.getLength()
rem         IF i>1 THEN
rem           LET cmd=cmd,IIF(m_bat,";",":")
rem         END IF
rem         LET cmd=cmd,os.Path.join(tmpdir,m_imgarr[i])
rem     END FOR
rem     LET cmd=cmd,IIF(m_bat,"&&"," ")
rem   END IF
rem   LET cmd=cmd,"fglrun ",os.Path.join(tmpdir,lastmodule)
rem   FOR i=1 TO num_args()
rem     LET arg=arg_val(i)
rem     CASE
rem       WHEN m_bat AND arg.getIndexOf(' ',1)==0 AND 
rem                      arg.getIndexOf(doublequote,1)==0
rem         LET cmd=cmd,' ',arg --we don't need quotes
rem       WHEN m_bat OR arg.getIndexOf(singlequote,1)!=0 
rem         --we must use double quotes on windows
rem         LET cmd=cmd,' ',doublequote,quoteDouble(arg),doublequote
rem       OTHERWISE
rem         --sh: you can't quote single quotes inside single quotes
rem         --everything else does not need to be quoted
rem         LET cmd=cmd,' ',singlequote,arg,singlequote
rem     END CASE
rem   END FOR
rem   --DISPLAY "cmd:",cmd
rem   CALL myrun(cmd)
rem END FUNCTION
rem 
rem FUNCTION myerr(err)
rem   DEFINE err STRING
rem   DISPLAY "ERROR:",err
rem   EXIT PROGRAM 1
rem END FUNCTION
rem 
rem FUNCTION eventuallyCompileFile()
rem   DEFINE cmd STRING
rem   CASE
rem     WHEN os.Path.extension(fname)=="4gl"
rem       LET cmd="cd ",tmpdir," && fglcomp -M ",fname
rem       CALL myrun(cmd)
rem       --DISPLAY "dirname:",fname,",basename:",os.Path.baseName(fname)
rem       LET lastmodule=os.Path.baseName(fname)
rem       --cut extension
rem       LET lastmodule=lastmodule.subString(1,lastmodule.getLength()-4)
rem       --DISPLAY "lastmodule=",lastmodule
rem     WHEN os.Path.extension(fname)=="per"
rem       LET cmd="cd ",tmpdir," && fglform -M ",fname
rem       CALL myrun(cmd)
rem     --other (resource) files are just copied
rem   END CASE
rem END FUNCTION
rem 
rem FUNCTION myrun(cmd)
rem   DEFINE cmd STRING, code INT
rem   --DISPLAY "myrun:",cmd
rem   RUN cmd RETURNING code
rem   IF code THEN
rem     EXIT PROGRAM 1
rem   END IF
rem END FUNCTION
rem 
rem FUNCTION checkSubdirs()
rem   DEFINE i,found INT
rem   DEFINE dir,err STRING
rem   DEFINE dirs DYNAMIC ARRAY OF STRING
rem   IF m_bat THEN
rem     RETURN 
rem   END IF
rem   LET dir=os.Path.fullPath(os.Path.dirName(full))
rem   WHILE TRUE
rem     CASE
rem       WHEN dir IS NULL
rem         EXIT WHILE
rem       WHEN dir==tmpdir
rem         LET found=true
rem         EXIT WHILE
rem       OTHERWISE
rem         CALL dirs.insertElement(1)
rem         LET dirs[1]=dir
rem     END CASE
rem     LET dir=os.Path.fullPath(os.Path.dirName(dir))
rem   END WHILE
rem   IF NOT found THEN
rem     --we can't use sfmt because of .bat echo pitfalls
rem     LET err=singlequote,fname,singlequote,' does point outside'
rem     CALL myerr(err)
rem   END IF
rem   FOR i=1 TO dirs.getLength()
rem     LET dir=dirs[i]
rem     IF NOT os.Path.exists(dir) THEN
rem       IF NOT os.Path.mkdir(dir) THEN
rem         LET err="Can't create directory:",dir
rem         CALL myerr(err)
rem       END IF
rem     END IF
rem   END FOR
rem END FUNCTION
rem 
rem FUNCTION quoteDouble(s)
rem   DEFINE s STRING
rem   DEFINE c STRING
rem   DEFINE i INT
rem   DEFINE sb base.StringBuffer
rem   LET sb=base.StringBuffer.create()
rem   FOR i=1 TO s.getLength()
rem     LET c=s.getCharAt(i)
rem     CASE
rem       WHEN c==doublequote
rem         CALL sb.append(backslash)
rem       WHEN (NOT m_bat) AND  c==backslash
rem         CALL sb.append(backslash)
rem     END CASE
rem     CALL sb.append(c)
rem   END FOR
rem   RETURN sb.toString()
rem END FUNCTION
rem 
rem FUNCTION isBinary(fname)
rem   DEFINE fname,ext STRING
rem   DEFINE i INT
rem   LET ext=os.Path.extension(fname)
rem   FOR i=1 TO m_binarr.getLength()
rem     IF m_binarr[i]==ext THEN 
rem       RETURN TRUE
rem     END IF
rem   END FOR
rem   RETURN FALSE
rem END FUNCTION
rem __CAT_EOF_END__
rem __CAT_EOF_BEGIN__:fglscriptify.4gl
rem IMPORT os
rem IMPORT util
rem DEFINE m_chw base.Channel
rem DEFINE m_outfile,m_lastsource STRING
rem --DEFINE m_minversion STRING
rem DEFINE m_optarr,m_sourcearr,m_binarr DYNAMIC ARRAY OF STRING
rem DEFINE m_bat,m_verbose INT
rem DEFINE m_envarr DYNAMIC ARRAY OF RECORD
rem   name STRING,
rem   value STRING
rem END RECORD
rem CONSTANT m_binfiles='["png","jpg","bmp","gif","tiff","wav","mp3","aiff","mpg"]'
rem MAIN
rem   CONSTANT R_READ=4
rem   CONSTANT R_EXECUTE=1
rem   DEFINE catsource STRING
rem   DEFINE ch base.Channel
rem   DEFINE line STRING
rem   DEFINE i,dummy INT
rem   CALL parseArgs()
rem   IF m_lastsource IS NULL THEN
rem     CALL myerr("No 4gl source has been added")
rem   END IF
rem   CALL util.JSON.parse(m_binfiles,m_binarr)
rem   IF m_outfile IS NULL THEN
rem     LET m_outfile=os.Path.baseName(m_lastsource)
rem     --subtract .4gl
rem     LET m_outfile=m_outfile.subString(1,m_outfile.getLength()-4)
rem   ELSE
rem     IF os.Path.extension(m_outfile)=="bat" THEN
rem       LET m_bat=TRUE
rem     END IF
rem   END IF
rem   IF m_verbose THEN
rem     DISPLAY "outfile:",m_outfile
rem     DISPLAY "sources:",util.JSON.stringify(m_sourcearr)
rem   END IF
rem   LET ch=base.Channel.create()
rem   LET m_chw=base.Channel.create()
rem   LET catsource="catsource"
rem   IF m_bat THEN
rem     LET catsource=catsource,".bat"
rem   ELSE
rem     LET catsource=catsource,".sh"
rem   END IF
rem   LET catsource=os.Path.join(os.Path.dirName(arg_val(0)),catsource)
rem   CALL ch.openFile(catsource,"r")
rem   CALL m_chw.openFile(m_outfile,"w")
rem   IF m_bat THEN
rem     CALL m_chw.writeLine("@echo off")
rem   ELSE
rem     CALL m_chw.writeLine("#!/bin/bash")
rem   END IF
rem   FOR i=1 TO m_envarr.getLength()
rem     IF m_bat THEN
rem       CALL m_chw.writeLine(sfmt("set %1=%2",m_envarr[i].name,m_envarr[i].value))
rem     ELSE
rem       CALL m_chw.writeLine(sfmt("export %1=%2",m_envarr[i].name,m_envarr[i].value))
rem     END IF
rem   END FOR
rem   WHILE (line:=ch.readLine()) IS NOT NULL
rem     CASE
rem       WHEN (m_bat AND line=="rem HERE_COMES_CATSOURCE") OR
rem            ((NOT m_bat) AND line=="#HERE_COMES_CATSOURCE")
rem         CALL insert_extractor()
rem       OTHERWISE
rem         CALL m_chw.writeLine(line)
rem     END CASE
rem   END WHILE
rem   CALL ch.close()
rem   FOR i=1 TO m_sourcearr.getLength()
rem     CALL appendSource(m_sourcearr[i])
rem   END FOR
rem   -- rights are -r-xr--r--
rem   CALL os.Path.chRwx(m_outfile, ((R_READ+R_EXECUTE)*64) + (R_READ*8) + R_READ ) RETURNING dummy
rem END MAIN
rem 
rem FUNCTION parseArgs()
rem   DEFINE i,len INT
rem   DEFINE arg,space,flagX,pre,post STRING
rem   FOR i=0 TO num_args()
rem     LET arg=arg_val(i)
rem     LET len=arg.getLength()
rem 
rem &define GETOPT(aopt,shortopt,longopt,desc,isFlag) \
rem     CASE \
rem       WHEN i==0 \
rem         IF LENGTH(longopt)>=10 THEN \
rem           LET space="\t" \
rem         ELSE \
rem           LET space="\t\t" \
rem         END IF \
rem         IF isFlag THEN \
rem           LET flagX = " yes " LET pre="(" LET post=")"\
rem         ELSE \
rem           LET flagX = " no  " LET pre="<" LET post=">"\
rem         END IF \
rem         LET m_optarr[m_optarr.getLength()+1]=flagX,shortopt,"     ",longopt,space," ",pre,desc,post \
rem       WHEN (arg==shortopt OR arg==longopt) AND (NOT isFlag) \
rem         LET i=i+1 \
rem         LET aopt=arg_val(i) \
rem         CONTINUE FOR \
rem       WHEN (arg==shortopt OR arg==longopt) AND isFlag \
rem         LET aopt=TRUE \
rem         CONTINUE FOR \
rem     END CASE
rem 
rem     GETOPT(m_outfile,"-o","--outfile","created script file",FALSE)
rem     --GETOPT(m_minversion,"-m","--minversion","minimum fglcomp version",FALSE)
rem     GETOPT(m_verbose,"-v","--verbose","prints some traces",TRUE)
rem     IF i==0 THEN CONTINUE FOR END IF
rem     -- process result_file according to system path
rem     IF (arg=="-e" OR arg=="--env") THEN
rem         LET i=i+1 
rem         CALL addRuntimeEnv(arg_val(i))
rem         CONTINUE FOR
rem     END IF
rem     IF arg.getCharAt(1) = '-' THEN
rem       DISPLAY SFMT("Option %1 is unknown.", arg)
rem       CALL help()
rem     END IF
rem     CALL addToSources(arg)
rem   END FOR
rem   IF num_args()=0 THEN
rem     CALL help()
rem   END IF
rem END FUNCTION
rem 
rem FUNCTION addRuntimeEnv(arg)
rem   DEFINE arg STRING
rem   DEFINE idx,new INT
rem   LET idx=arg.getIndexOf("=",1)
rem   IF idx==0 THEN
rem     RETURN 
rem   END IF
rem   LET new=m_envarr.getLength()+1
rem   LET m_envarr[new].name=arg.subString(1,idx-1)
rem   LET m_envarr[new].value=arg.subString(idx+1,arg.getLength())
rem END FUNCTION
rem 
rem FUNCTION addToSources(fname)
rem   DEFINE fname STRING
rem   IF NOT os.Path.exists(fname) THEN
rem     CALL myerr(sfmt("Can't find '%1'",fname))
rem   END IF
rem   IF os.Path.isDirectory(fname) THEN
rem     CALL myerr(sfmt("'%1' is a directory, can only add regular files",fname))
rem   END IF
rem   CALL checkIsInPath(fname)
rem   LET m_sourcearr[m_sourcearr.getLength()+1]=fname
rem   IF os.Path.extension(fname)=="4gl" THEN
rem     LET m_lastsource=fname
rem   END IF
rem END FUNCTION
rem 
rem --we allow only file names which are inside our current dir
rem --(and sub dirs)
rem FUNCTION checkIsInPath(fname)
rem   DEFINE fname STRING
rem   DEFINE fullpwd,dir STRING
rem   DEFINE found INT
rem   LET fullpwd=os.Path.fullPath(os.Path.pwd())
rem   LET dir=os.Path.fullPath(os.Path.dirName(fname))
rem   WHILE dir IS NOT NULL 
rem     IF dir==fullpwd THEN
rem       LET found=TRUE
rem       EXIT WHILE
rem     END IF
rem     LET dir=os.Path.fullPath(os.Path.dirName(dir))
rem   END WHILE
rem   IF NOT found THEN
rem     CALL myerr(sfmt("'%1' is not inside our current directories subtree",fname))
rem   END IF
rem END FUNCTION
rem 
rem 
rem FUNCTION help()
rem   DEFINE i INT
rem   DEFINE progname STRING
rem   LET progname=fgl_getenv("_CALLING_SCRIPT")
rem   IF progname IS NULL THEN
rem     LET progname="fglscriptify"
rem   END IF
rem   DISPLAY "usage: ",progname," ?option? ... ?file? <4glmain>"
rem   DISPLAY "Possible options:"
rem   DISPLAY   "  Flag short   long\t\t Value or Description"
rem   DISPLAY   "   no  -e     --env\t\t <ENV>=<value>"
rem   FOR i=1 TO m_optarr.getLength()
rem     DISPLAY "  ",m_optarr[i]
rem   END FOR
rem   EXIT PROGRAM 1
rem END FUNCTION
rem 
rem FUNCTION insert_extractor()
rem   DEFINE ch base.Channel
rem   DEFINE line,whitesp,catsource4gl STRING
rem   CONSTANT perc="%"
rem   LET ch=base.Channel.create()
rem   LET catsource4gl=os.Path.join(os.Path.dirName(arg_val(0)),"catsource.4gl")
rem   CALL ch.openFile(catsource4gl,"r")
rem   WHILE (line:=ch.readLine()) IS NOT NULL
rem     IF m_bat THEN
rem       LET whitesp=line CLIPPED
rem       IF whitesp.getLength()==0 THEN --echo with spaces produces ECHO off
rem         LET line="--"
rem       END IF
rem       CALL m_chw.writeLine(sfmt("echo %1 >> %2extractor%3",line,perc,perc))
rem     ELSE
rem       CALL m_chw.writeLine(line) 
rem     END IF
rem   END WHILE
rem   CALL ch.close()
rem END FUNCTION
rem 
rem FUNCTION appendSource(fname)
rem   DEFINE fname,ext STRING
rem   DEFINE ch base.Channel
rem   DEFINE pre,line STRING
rem   LET ch=base.Channel.create()
rem   CALL ch.openFile(fname,"r")
rem   IF m_bat THEN
rem     LET pre="rem "
rem   ELSE
rem     LET pre="#"
rem   END IF
rem   CALL m_chw.writeLine(sfmt("%1__CAT_EOF_BEGIN__:%2",pre,fname))
rem   LET ext=os.Path.extension(fname)
rem   IF isBinary(fname) THEN
rem     CALL writeBinary(fname,pre) 
rem   ELSE
rem     WHILE (line:=ch.readLine()) IS NOT NULL
rem       CALL m_chw.writeLine(sfmt("%1%2",pre,line))
rem     END WHILE
rem   END IF
rem   CALL m_chw.writeLine(sfmt("%1__CAT_EOF_END__",pre))
rem   CALL ch.close()
rem END FUNCTION
rem 
rem FUNCTION isBinary(fname)
rem   DEFINE fname,ext STRING
rem   DEFINE i INT
rem   LET ext=os.Path.extension(fname)
rem   FOR i=1 TO m_binarr.getLength()
rem     IF m_binarr[i]==ext THEN 
rem       RETURN TRUE
rem     END IF
rem   END FOR
rem   RETURN FALSE
rem END FUNCTION
rem 
rem FUNCTION mysub(base64,index,linelength,len)
rem   DEFINE base64 STRING
rem   DEFINE index,linelength,len,endindex INT
rem   LET endindex=index+linelength-1
rem   RETURN base64.subString(index,IIF(endindex>len,len,endindex))
rem END FUNCTION
rem 
rem FUNCTION writeBinary(fname,pre)
rem   DEFINE fname,pre STRING
rem   DEFINE base64,chunk STRING
rem   DEFINE index,linelength,len INT
rem   LET linelength=IIF(m_bat,76,79)
rem   LET index=1
rem   LET base64=util.Strings.base64Encode(fname)
rem   LET len=base64.getLength()
rem   --spit out 80 char pieces
rem   LET chunk=mysub(base64,index,linelength,len)
rem   WHILE chunk.getLength()>0
rem     CALL m_chw.writeLine(sfmt("%1%2",pre,chunk))
rem     LET index=index+linelength
rem     LET chunk=mysub(base64,index,linelength,len)
rem   END WHILE
rem END FUNCTION
rem 
rem FUNCTION myerr(err)
rem   DEFINE err STRING
rem   DISPLAY "ERROR:",err
rem   EXIT PROGRAM 1
rem END FUNCTION
rem __CAT_EOF_END__
