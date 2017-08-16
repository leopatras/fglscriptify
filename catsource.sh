#!/bin/bash
DIR=`dirname "$0"`
#echo "DIR='$DIR'"
pushd "$DIR" >/dev/null
BINDIR=`pwd`
#echo "BINDIR='$BINDIR'"
popd > /dev/null
export _CATFILE="$BINDIR/`basename $0`"
export _CALLING_SCRIPT=`basename $0`
#echo "me:$_CATFILE"
firstcheck=`mktemp`
fglrun -V > $firstcheck
if [ $? -ne 0 ]
then
  rm -f $firstcheck
  echo "ERROR: no fglrun in the path"
  exit 1
fi
ver=`cat $firstcheck | sed -n '/Genero virtual machine/q;p'`
major=`echo $ver | sed -n 's/^.* \([0-9]*\)\.\([0-9]*\).*$/\1/p'`
rm -f $firstcheck
if [ $major -lt 3 ]
then
  echo "ERROR:fglrun version should be >= 3.0 ,current:$ver"
  exit 1
fi

replace_dot(){
# replace dot with underscore
  local dir=`dirname $1`
  local base=`basename $1`
#genero doesn't like dots in the filename
  base=`echo $base | sed -e 's/\./_/g'`
  echo "$dir/$base"
}

# compute a unique temp filename and a unique directory
# without dots in the name
while true
do
  _tmpfile=`mktemp`
  _tmpdir_extractor=`dirname $_tmpfile`
  rm -f $_tmpfile
  _tmpfile=`replace_dot $_tmpfile`

  _TMPDIR=`mktemp -d`
  rm -rf $_TMPDIR
  export _TMPDIR=`replace_dot $_TMPDIR`

  if [ ! -e $_tmpfile ] && [ ! -e $_TMPDIR ]
  then
    break
  fi
done
#echo "_tmpfile:$_tmpfile,_tmpdir_extractor:$_tmpdir_extractor,_TMPDIR:$_TMPDIR"

#we insert catsource.4gl on the next lines
cat >$_tmpfile.4gl <<EOF
#HERE_COMES_CATSOURCE
EOF

#now compile and run catsource from the temp location
pushd `pwd` > /dev/null
cd $_tmpdir_extractor
mybase=`basename $_tmpfile`
fglcomp -M $mybase.4gl
if [ $? -ne 0 ]
then
  exit 1
fi
rm -f $mybase.4gl
popd > /dev/null
fglrun $_tmpfile.42m "$@"
mycode=$?
rm -f $_tmpfile.42m
rm -rf $_TMPDIR
exit $mycode
