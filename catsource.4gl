--note: some 4gl constructs in this file are there to surround the pitfalls
--of echo'ing this file with the windows echo command to a temp 4gl file
--percent signs are avoided as well as or signs, thats why we avoid
--the sfmt operator and the cat operator and mixing quotes with double quotes
OPTIONS SHORT CIRCUIT
IMPORT util
IMPORT os
DEFINE tmpdir,fname,full,lastmodule STRING
DEFINE m_bat INT
DEFINE singlequote,doublequote,backslash,percent,dollar STRING
DEFINE m_binTypeArr,m_resTypeArr,m_imgarr,m_resarr DYNAMIC ARRAY OF STRING
MAIN
  DEFINE line,err,catfile STRING
  DEFINE ch,chw base.Channel
  DEFINE sb base.StringBuffer
  DEFINE write,writebin INT
  LET singlequote=ASCII(39)
  LET doublequote=ASCII(34)
  LET backslash=ASCII(92) --we must not use the literal here
  LET percent=ASCII(37)
  LET dollar=ASCII(36)
  LET m_binTypeArr[m_binTypeArr.getLength()+1]='png' 
  LET m_binTypeArr[m_binTypeArr.getLength()+1]='jpg'
  LET m_binTypeArr[m_binTypeArr.getLength()+1]='bmp'
  LET m_binTypeArr[m_binTypeArr.getLength()+1]='gif'
  LET m_binTypeArr[m_binTypeArr.getLength()+1]='tiff'
  LET m_binTypeArr[m_binTypeArr.getLength()+1]='wav'
  LET m_binTypeArr[m_binTypeArr.getLength()+1]='mp3'
  LET m_binTypeArr[m_binTypeArr.getLength()+1]='aiff'
  LET m_binTypeArr[m_binTypeArr.getLength()+1]='mpg'

  LET m_resTypeArr[m_resTypeArr.getLength()+1]='per' 
  LET m_resTypeArr[m_resTypeArr.getLength()+1]='4st'
  LET m_resTypeArr[m_resTypeArr.getLength()+1]='4tb'
  LET m_resTypeArr[m_resTypeArr.getLength()+1]='4tm'
  LET m_resTypeArr[m_resTypeArr.getLength()+1]='4sm'
  LET m_resTypeArr[m_resTypeArr.getLength()+1]='iem'
  LET sb=base.StringBuffer.create()
  LET catfile=fgl_getenv("_CATFILE") --set by calling script
  LET tmpdir=fgl_getenv("_TMPDIR") --set by calling script
  LET m_bat=fgl_getenv("_IS_BAT_FILE") IS NOT NULL
  IF catfile IS NULL OR tmpdir IS NULL THEN
    CALL myerr("_CATFILE or _TMPDIR not set")
  END IF
  IF catfile IS NULL THEN
    LET catfile=arg_val(1)
    LET tmpdir=arg_val(2)
  END IF
  IF NOT m_bat THEN --windows fullPath is clumsy
    LET tmpdir=os.Path.fullPath(tmpdir)
  END IF
  LET ch=base.Channel.create()
  LET chw=base.Channel.create()
  IF NOT os.Path.exists(tmpdir) THEN
    IF NOT os.Path.mkdir(tmpdir) THEN
      LET err="Can't mkdir :",tmpdir
      CALL myerr(err)
    END IF
  END IF
  CALL ch.openFile(catfile,"r")
  WHILE (line:=ch.readLine()) IS NOT NULL
    CASE
       WHEN m_bat AND line.getIndexOf("rem __CAT_EOF_BEGIN__:",1)==1
         LET fname=line.subString(23,line.getLength())
         GOTO mark1
       WHEN (NOT m_bat) AND  line.getIndexOf("#__CAT_EOF_BEGIN__:",1)==1
         LET fname=line.subString(20,line.getLength())
       LABEL mark1:
         LET full=os.Path.join(tmpdir,fname)
         CALL checkSubdirs()
         IF isBinary(fname) THEN
           LET writebin=TRUE
           CALL addDir(m_imgarr,os.Path.dirName(fname))
           CALL sb.clear()
         ELSE
           IF isResource(fname) THEN
             CALL addDir(m_resarr,os.Path.dirName(fname))
           END IF
           LET write=TRUE
           CALL chw.openFile(full,"w")
         END IF
       WHEN ((NOT m_bat) AND line=="#__CAT_EOF_END__") OR
            (m_bat AND line=="rem __CAT_EOF_END__")
         IF writebin THEN
           LET writebin=FALSE
           CALL util.Strings.base64Decode(sb.toString(),full)
         ELSE
           LET write=FALSE
           CALL chw.close()
           CALL eventuallyCompileFile()
         END IF
       WHEN writebin
         CALL sb.append(line.subString(IIF(m_bat,5,2),line.getLength()))
       WHEN write
         CALL chw.writeLine(line.subString(IIF(m_bat,5,2),line.getLength()))
    END CASE
  END WHILE
  CALL ch.close()
  CALL runLastModule()
END MAIN

FUNCTION addDir(arr,dirname)
  DEFINE arr DYNAMIC ARRAY OF STRING
  DEFINE dirname STRING
  DEFINE i INT
  FOR i=1 TO arr.getLength()
    IF arr[i]=dirname THEN
      RETURN --already contained
    END IF
  END FOR
  LET arr[arr.getLength()+1]=dirname
END FUNCTION

FUNCTION setPathFor(arr,envName,cmd)
  DEFINE arr DYNAMIC ARRAY OF STRING
  DEFINE envName,tmp STRING
  DEFINE cmd STRING
  DEFINE i INT
  IF arr.getLength()>0 THEN
    LET tmp=envName,"="
    LET cmd=cmd,IIF(m_bat,"set ",""),tmp
    IF fgl_getenv(envName) IS NOT NULL THEN
      IF m_bat THEN
        LET cmd=percent,envName,percent,";"
      ELSE
        LET cmd=dollar,envName,":"
      END IF
    END IF
    FOR i=1 TO arr.getLength()
        IF i>1 THEN
          LET cmd=cmd,IIF(m_bat,";",":")
        END IF
        LET cmd=cmd,quotePath(os.Path.join(tmpdir,arr[i]))
    END FOR
    LET cmd=cmd,IIF(m_bat,"&&"," ")
  END IF
  RETURN cmd
END FUNCTION

FUNCTION runLastModule() --we must get argument quoting right
  DEFINE i INT
  DEFINE arg,cmd,cmdsave,image2font STRING
  IF lastmodule IS NULL THEN RETURN END IF
  LET cmd=setPathFor(m_resarr,"FGLRESOURCEPATH",cmd)
  LET image2font=os.Path.join(os.Path.join(fgl_getenv("FGLDIR"),"lib"),"image2font.txt")
  LET cmdsave=cmd
  LET cmd=setPathFor(m_imgarr,"FGLIMAGEPATH",cmd)
  IF cmd!=cmdsave AND os.Path.exists(image2font) THEN
    IF m_bat THEN
      LET cmd=cmd.subString(1,cmd.getLength()-2),";",quotePath(image2font),"&&"
    ELSE
      LET cmd=cmd.subString(1,cmd.getLength()-1),":",quotePath(image2font)," "
    END IF
  END IF
  LET cmd=cmd,"fglrun ",os.Path.join(tmpdir,lastmodule)
  FOR i=1 TO num_args()
    LET arg=arg_val(i)
    CASE
      WHEN m_bat AND arg.getIndexOf(' ',1)==0 AND 
                     arg.getIndexOf(doublequote,1)==0
        LET cmd=cmd,' ',arg --we don't need quotes
      WHEN m_bat OR arg.getIndexOf(singlequote,1)!=0 
        --we must use double quotes on windows
        LET cmd=cmd,' ',doublequote,quoteDouble(arg),doublequote
      OTHERWISE
        --sh: you can't quote single quotes inside single quotes
        --everything else does not need to be quoted
        LET cmd=cmd,' ',singlequote,arg,singlequote
    END CASE
  END FOR
  --DISPLAY "cmd:",cmd
  CALL myrun(cmd)
END FUNCTION

FUNCTION quotePath(p)
  DEFINE p STRING
  --TODO: quote space with backlash space
  --IF NOT m_bat AND p.getIndexOf(" ",1)!=0
    --RETURN quoteSpace(p)
  --END IF
  RETURN p
END FUNCTION

FUNCTION myerr(err)
  DEFINE err STRING
  DISPLAY "ERROR:",err
  EXIT PROGRAM 1
END FUNCTION

FUNCTION eventuallyCompileFile()
  DEFINE cmd STRING
  CASE
    WHEN os.Path.extension(fname)=="4gl"
      LET cmd="cd ",tmpdir," && fglcomp -M ",fname
      CALL myrun(cmd)
      --DISPLAY "dirname:",fname,",basename:",os.Path.baseName(fname)
      LET lastmodule=os.Path.baseName(fname)
      --cut extension
      LET lastmodule=lastmodule.subString(1,lastmodule.getLength()-4)
      --DISPLAY "lastmodule=",lastmodule
    WHEN os.Path.extension(fname)=="per"
      LET cmd="cd ",tmpdir," && fglform -M ",fname
      CALL myrun(cmd)
    --other (resource) files are just copied
  END CASE
END FUNCTION

FUNCTION myrun(cmd)
  DEFINE cmd STRING, code INT
  --DISPLAY "myrun:",cmd
  RUN cmd RETURNING code
  IF code THEN
    EXIT PROGRAM 1
  END IF
END FUNCTION

FUNCTION checkSubdirs()
  DEFINE i,found INT
  DEFINE dir,err STRING
  DEFINE dirs DYNAMIC ARRAY OF STRING
  LET dir=os.Path.fullPath(os.Path.dirName(full))
  WHILE TRUE
    CASE
      WHEN dir IS NULL
        EXIT WHILE
      WHEN dir==tmpdir
        LET found=true
        EXIT WHILE
      OTHERWISE
        CALL dirs.insertElement(1)
        LET dirs[1]=dir
    END CASE
    LET dir=os.Path.fullPath(os.Path.dirName(dir))
  END WHILE
  IF NOT found THEN
    --we can't use sfmt because of .bat echo pitfalls
    LET err=singlequote,fname,singlequote,' does point outside'
    CALL myerr(err)
  END IF
  FOR i=1 TO dirs.getLength()
    LET dir=dirs[i]
    IF NOT os.Path.exists(dir) THEN
      IF NOT os.Path.mkdir(dir) THEN
        LET err="Can't create directory:",dir
        CALL myerr(err)
      END IF
    END IF
  END FOR
END FUNCTION

FUNCTION quoteDouble(s)
  DEFINE s STRING
  DEFINE c STRING
  DEFINE i INT
  DEFINE sb base.StringBuffer
  LET sb=base.StringBuffer.create()
  FOR i=1 TO s.getLength()
    LET c=s.getCharAt(i)
    CASE
      WHEN c==doublequote
        CALL sb.append(backslash)
      WHEN (NOT m_bat) AND  c==backslash
        CALL sb.append(backslash)
    END CASE
    CALL sb.append(c)
  END FOR
  RETURN sb.toString()
END FUNCTION

FUNCTION isInArray(arr,fname)
  DEFINE arr DYNAMIC ARRAY OF STRING
  DEFINE fname,ext STRING
  DEFINE i INT
  LET ext=os.Path.extension(fname)
  FOR i=1 TO arr.getLength()
    IF arr[i]==ext THEN 
      RETURN TRUE
    END IF
  END FOR
  RETURN FALSE
END FUNCTION

FUNCTION isBinary(fname)
  DEFINE fname STRING
  RETURN isInArray(m_binTypeArr,fname)
END FUNCTION

FUNCTION isResource(fname)
  DEFINE fname STRING
  RETURN isInArray(m_resTypeArr,fname)
END FUNCTION

