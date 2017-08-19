# fglscriptify

create Genero 4gl "scripts" from 4GL source and resource files

## Motivation

Did you ever run into the trouble of getting 
```
Module 'foo.42m': Bad version: Recompile your sources.
```
?

As I'm frequently changing Genero environments and the tools are now outside the fgl distribution I got this too often in the past.

fglscriptify changes this by creating a shell script/.bat file  containing all sources and resources.

Upon launch the sources are extracted into a temporary directory, 
compiled with the current Genero fglcomp/fglform tools and run with the current fglrun.
So in fact fglscriptify produces self extracting and self compiling scripts which are directly executable.

## Installation

fglscriptify did already scriptify itself and is distributed (of course ) as a single shell script/.bat file.

You can call it directly by specififying the path to it or copy it into a directory contained in the PATH variable.

## Usage

```
fglscriptify ?-o outputname? file ... mainmodule.4gl
```

If -outputname is omitted the script gets the name of the last 4GL module added.The last 4GL module added must be also the one containing the MAIN of the program.

## Samples 

creates a script named foo
```
$ fglscriptify foo.per foo.4gl 
```

creates a windows script foo.bat, the .bat extension is the indicator to create a Windows script.
```
$ fglscriptify -o foo.bat foo.per foo.4gl 
```

creates a script using internally a text file
```
$ fglscriptify foo.txt foo.4gl 
```

Accessing the text file in the program is
```
  LET txtfile=os.Path.join(os.Path.dirname(arg_val(0)),"foo.txt")
```

