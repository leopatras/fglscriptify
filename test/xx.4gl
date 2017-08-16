IMPORT os
MAIN
  DEFINE i INT
  DEFINE cmd STRING
  FOR i=1 TO num_args()
    DISPLAY sfmt("arg%1:%2:",i,arg_val(i))
  END FOR
  DISPLAY "FGLIMAGEPATH=",fgl_getenv("FGLIMAGEPATH")
  DISPLAY "DBPATH=",fgl_getenv("DBPATH")
  LET cmd="open"
  IF fgl_getenv("WINDIR") IS NOT NULL THEN
    LET cmd="start"
  END IF
  LET cmd=cmd," ",os.Path.join(os.Path.dirname(arg_val(0)),"next.png")
  DISPLAY "cmd:",cmd
  RUN cmd
  SLEEP 2
END MAIN
