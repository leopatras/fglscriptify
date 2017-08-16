--note: some 4gl constructs in this file are there to surround the pitfalls
--of echo'ing this file with the windows echo command to a temp 4gl file
--percent signs are avoided as well as or signs, thats why we avoid
--the sfmt operator and the cat operator and mixing quotes with double quotes
OPTIONS SHORT CIRCUIT
IMPORT util
IMPORT os
DEFINE tmpdir,fname,full,lastmodule STRING
DEFINE m_bat INT
DEFINE singlequote,doublequote,backslash STRING
DEFINE m_binarr DYNAMIC ARRAY OF STRING
MAIN
  DEFINE line,err,catfile STRING
  DEFINE ch,chw base.Channel
  DEFINE sb base.StringBuffer
  DEFINE write,writebin INT
  LET singlequote=ASCII(39)
  LET doublequote=ASCII(34)
  LET backslash=ASCII(92) --we must not use the literal here
  LET m_binarr[m_binarr.getLength()+1]='png' 
  LET m_binarr[m_binarr.getLength()+1]='jpg'
  LET m_binarr[m_binarr.getLength()+1]='bmp'
  LET m_binarr[m_binarr.getLength()+1]='gif'
  LET m_binarr[m_binarr.getLength()+1]='tiff'
  LET m_binarr[m_binarr.getLength()+1]='wav'
  LET m_binarr[m_binarr.getLength()+1]='mp3'
  LET m_binarr[m_binarr.getLength()+1]='aiff'
  LET m_binarr[m_binarr.getLength()+1]='mpg'
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
           CALL sb.clear()
         ELSE
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

FUNCTION runLastModule() --we must get argument quoting right
  DEFINE i INT
  DEFINE arg,cmd STRING
  IF lastmodule IS NULL THEN RETURN END IF
  LET cmd="fglrun ",os.Path.join(tmpdir,lastmodule)
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
  IF m_bat THEN
    RETURN 
  END IF
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
