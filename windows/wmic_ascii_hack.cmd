@echo off
REM wmic.exe has trouble dealing with locale and ignores attempts to override the default UTF16 output encoding
REM partially based on https://superuser.com/questions/812438/combine-batch-wmic-ansi-unicode-output-formatting
REM see also https://toster.ru/q/638585?e=7688598#clarification_708255
REM NOTE the naive command below will not work when the output.txt does not originally exist the output will be created in UTF16:
REM wmic.exe /LOCALE:MS_409 /OUTPUT:output.txt os get caption

set RESULT=%1
if /i "%RESULT%" EQU "" set RESULT=result.txt
shift
set COMMAND=os get Caption
echo.>%RESULT%
echo.>>%RESULT%
REM result.txt has 4 bytes and no BOM
wmic.exe /LOCALE:MS_409 /APPEND:%RESULT% /OUTPUT:null %COMMAND%
REM result.txt has the query output
REM Caption
REM Microsoft Windows 8.1
REM and no BOM

findstr.exe -mic:"windows" %RESULT%
type %RESULT%
goto :EOF
