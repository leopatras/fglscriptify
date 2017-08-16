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
rem HERE_COMES_CATSOURCE
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
