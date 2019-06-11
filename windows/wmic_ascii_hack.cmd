@echo off
REM wmic.exe has trouble dealing with locale and ignores attempts to override the default UTF16 output encoding
REM partially based on https://superuser.com/questions/812438/combine-batch-wmic-ansi-unicode-output-formatting
REM see also https://toster.ru/q/638585?e=7688598#clarification_708255
set RESULT=%1
if /i "%RESULT%" EQU "" set RESULT=result.txt
echo.>%RESULT%
echo.>>%RESULT%
REM result.txt has 4 bytes and no BOM
wmic.exe /LOCALE:MS_409 /APPEND:%RESULT% /OUTPUT:null os get Caption
REM result.txt has the query output
REM Caption
REM Microsoft Windows 8.1
REM and no BOM

findstr.exe -mic:"windows" %RESULT%
type %RESULT%
goto :EOF
