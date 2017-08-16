IMPORT os
IMPORT util
DEFINE m_chw base.Channel
DEFINE m_outfile,m_lastsource STRING
--DEFINE m_minversion STRING
DEFINE m_optarr,m_sourcearr,m_binarr DYNAMIC ARRAY OF STRING
DEFINE m_bat,m_verbose INT
DEFINE m_envarr DYNAMIC ARRAY OF RECORD
  name STRING,
  value STRING
END RECORD
CONSTANT m_binfiles='["png","jpg","bmp","gif","tiff","wav","mp3","aiff","mpg"]'
MAIN
  CONSTANT R_READ=4
  CONSTANT R_EXECUTE=1
  DEFINE catsource STRING
  DEFINE ch base.Channel
  DEFINE line STRING
  DEFINE i,dummy INT
  CALL parseArgs()
  IF m_lastsource IS NULL THEN
    CALL myerr("No 4gl source has been added")
  END IF
  CALL util.JSON.parse(m_binfiles,m_binarr)
  IF m_outfile IS NULL THEN
    LET m_outfile=os.Path.baseName(m_lastsource)
    --subtract .4gl
    LET m_outfile=m_outfile.subString(1,m_outfile.getLength()-4)
  ELSE
    IF os.Path.extension(m_outfile)=="bat" THEN
      LET m_bat=TRUE
    END IF
  END IF
  IF m_verbose THEN
    DISPLAY "outfile:",m_outfile
    DISPLAY "sources:",util.JSON.stringify(m_sourcearr)
  END IF
  LET ch=base.Channel.create()
  LET m_chw=base.Channel.create()
  LET catsource="catsource"
  IF m_bat THEN
    LET catsource=catsource,".bat"
  ELSE
    LET catsource=catsource,".sh"
  END IF
  LET catsource=os.Path.join(os.Path.dirName(arg_val(0)),catsource)
  CALL ch.openFile(catsource,"r")
  CALL m_chw.openFile(m_outfile,"w")
  IF m_bat THEN
    CALL m_chw.writeLine("@echo off")
  ELSE
    CALL m_chw.writeLine("#!/bin/bash")
  END IF
  FOR i=1 TO m_envarr.getLength()
    IF m_bat THEN
      CALL m_chw.writeLine(sfmt("set %1=%2",m_envarr[i].name,m_envarr[i].value))
    ELSE
      CALL m_chw.writeLine(sfmt("export %1=%2",m_envarr[i].name,m_envarr[i].value))
    END IF
  END FOR
  WHILE (line:=ch.readLine()) IS NOT NULL
    CASE
      WHEN (m_bat AND line=="rem HERE_COMES_CATSOURCE") OR
           ((NOT m_bat) AND line=="#HERE_COMES_CATSOURCE")
        CALL insert_extractor()
      OTHERWISE
        CALL m_chw.writeLine(line)
    END CASE
  END WHILE
  CALL ch.close()
  FOR i=1 TO m_sourcearr.getLength()
    CALL appendSource(m_sourcearr[i])
  END FOR
  -- rights are -r-xr--r--
  CALL os.Path.chRwx(m_outfile, ((R_READ+R_EXECUTE)*64) + (R_READ*8) + R_READ ) RETURNING dummy
END MAIN

FUNCTION parseArgs()
  DEFINE i,len INT
  DEFINE arg,space,flagX,pre,post STRING
  FOR i=0 TO num_args()
    LET arg=arg_val(i)
    LET len=arg.getLength()

&define GETOPT(aopt,shortopt,longopt,desc,isFlag) \
    CASE \
      WHEN i==0 \
        IF LENGTH(longopt)>=10 THEN \
          LET space="\t" \
        ELSE \
          LET space="\t\t" \
        END IF \
        IF isFlag THEN \
          LET flagX = " yes " LET pre="(" LET post=")"\
        ELSE \
          LET flagX = " no  " LET pre="<" LET post=">"\
        END IF \
        LET m_optarr[m_optarr.getLength()+1]=flagX,shortopt,"     ",longopt,space," ",pre,desc,post \
      WHEN (arg==shortopt OR arg==longopt) AND (NOT isFlag) \
        LET i=i+1 \
        LET aopt=arg_val(i) \
        CONTINUE FOR \
      WHEN (arg==shortopt OR arg==longopt) AND isFlag \
        LET aopt=TRUE \
        CONTINUE FOR \
    END CASE

    GETOPT(m_outfile,"-o","--outfile","created script file",FALSE)
    --GETOPT(m_minversion,"-m","--minversion","minimum fglcomp version",FALSE)
    GETOPT(m_verbose,"-v","--verbose","prints some traces",TRUE)
    IF i==0 THEN CONTINUE FOR END IF
    -- process result_file according to system path
    IF (arg=="-e" OR arg=="--env") THEN
        LET i=i+1 
        CALL addRuntimeEnv(arg_val(i))
        CONTINUE FOR
    END IF
    IF arg.getCharAt(1) = '-' THEN
      DISPLAY SFMT("Option %1 is unknown.", arg)
      CALL help()
    END IF
    CALL addToSources(arg)
  END FOR
  IF num_args()=0 THEN
    CALL help()
  END IF
END FUNCTION

FUNCTION addRuntimeEnv(arg)
  DEFINE arg STRING
  DEFINE idx,new INT
  LET idx=arg.getIndexOf("=",1)
  IF idx==0 THEN
    RETURN 
  END IF
  LET new=m_envarr.getLength()+1
  LET m_envarr[new].name=arg.subString(1,idx-1)
  LET m_envarr[new].value=arg.subString(idx+1,arg.getLength())
END FUNCTION

FUNCTION addToSources(fname)
  DEFINE fname STRING
  IF NOT os.Path.exists(fname) THEN
    CALL myerr(sfmt("Can't find '%1'",fname))
  END IF
  IF os.Path.isDirectory(fname) THEN
    CALL myerr(sfmt("'%1' is a directory, can only add regular files",fname))
  END IF
  CALL checkIsInPath(fname)
  LET m_sourcearr[m_sourcearr.getLength()+1]=fname
  IF os.Path.extension(fname)=="4gl" THEN
    LET m_lastsource=fname
  END IF
END FUNCTION

--we allow only file names which are inside our current dir
--(and sub dirs)
FUNCTION checkIsInPath(fname)
  DEFINE fname STRING
  DEFINE fullpwd,dir STRING
  DEFINE found INT
  LET fullpwd=os.Path.fullPath(os.Path.pwd())
  LET dir=os.Path.fullPath(os.Path.dirName(fname))
  WHILE dir IS NOT NULL 
    IF dir==fullpwd THEN
      LET found=TRUE
      EXIT WHILE
    END IF
    LET dir=os.Path.fullPath(os.Path.dirName(dir))
  END WHILE
  IF NOT found THEN
    CALL myerr(sfmt("'%1' is not inside our current directories subtree",fname))
  END IF
END FUNCTION


FUNCTION help()
  DEFINE i INT
  DEFINE progname STRING
  LET progname=fgl_getenv("_CALLING_SCRIPT")
  IF progname IS NULL THEN
    LET progname="fglscriptify"
  END IF
  DISPLAY "usage: ",progname," ?option? ... ?file? <4glmain>"
  DISPLAY "Possible options:"
  DISPLAY   "  Flag short   long\t\t Value or Description"
  DISPLAY   "   no  -e     --env\t\t <ENV>=<value>"
  FOR i=1 TO m_optarr.getLength()
    DISPLAY "  ",m_optarr[i]
  END FOR
  EXIT PROGRAM 1
END FUNCTION

FUNCTION insert_extractor()
  DEFINE ch base.Channel
  DEFINE line,whitesp,catsource4gl STRING
  CONSTANT perc="%"
  LET ch=base.Channel.create()
  LET catsource4gl=os.Path.join(os.Path.dirName(arg_val(0)),"catsource.4gl")
  CALL ch.openFile(catsource4gl,"r")
  WHILE (line:=ch.readLine()) IS NOT NULL
    IF m_bat THEN
      LET whitesp=line CLIPPED
      IF whitesp.getLength()==0 THEN --echo with spaces produces ECHO off
        LET line="--"
      END IF
      CALL m_chw.writeLine(sfmt("echo %1 >> %2extractor%3",line,perc,perc))
    ELSE
      CALL m_chw.writeLine(line) 
    END IF
  END WHILE
  CALL ch.close()
END FUNCTION

FUNCTION appendSource(fname)
  DEFINE fname,ext STRING
  DEFINE ch base.Channel
  DEFINE pre,line STRING
  LET ch=base.Channel.create()
  CALL ch.openFile(fname,"r")
  IF m_bat THEN
    LET pre="rem "
  ELSE
    LET pre="#"
  END IF
  CALL m_chw.writeLine(sfmt("%1__CAT_EOF_BEGIN__:%2",pre,fname))
  LET ext=os.Path.extension(fname)
  IF isBinary(fname) THEN
    CALL writeBinary(fname,pre) 
  ELSE
    WHILE (line:=ch.readLine()) IS NOT NULL
      CALL m_chw.writeLine(sfmt("%1%2",pre,line))
    END WHILE
  END IF
  CALL m_chw.writeLine(sfmt("%1__CAT_EOF_END__",pre))
  CALL ch.close()
END FUNCTION

FUNCTION isBinary(fname)
  DEFINE fname,ext STRING
  DEFINE i INT
  LET ext=os.Path.extension(fname)
  FOR i=1 TO m_binarr.getLength()
    IF m_binarr[i]==ext THEN 
      RETURN TRUE
    END IF
  END FOR
  RETURN FALSE
END FUNCTION

FUNCTION mysub(base64,index,linelength,len)
  DEFINE base64 STRING
  DEFINE index,linelength,len,endindex INT
  LET endindex=index+linelength-1
  RETURN base64.subString(index,IIF(endindex>len,len,endindex))
END FUNCTION

FUNCTION writeBinary(fname,pre)
  DEFINE fname,pre STRING
  DEFINE base64,chunk STRING
  DEFINE index,linelength,len INT
  LET linelength=IIF(m_bat,76,79)
  LET index=1
  LET base64=util.Strings.base64Encode(fname)
  LET len=base64.getLength()
  --spit out 80 char pieces
  LET chunk=mysub(base64,index,linelength,len)
  WHILE chunk.getLength()>0
    CALL m_chw.writeLine(sfmt("%1%2",pre,chunk))
    LET index=index+linelength
    LET chunk=mysub(base64,index,linelength,len)
  END WHILE
END FUNCTION

FUNCTION myerr(err)
  DEFINE err STRING
  DISPLAY "ERROR:",err
  EXIT PROGRAM 1
END FUNCTION
