@echo OFF
REM origin: https://toster.ru/q/650782
set varcount=0
for /F "tokens=2" %%a in (%1) do set /A varcount+=1
if not %varcount%==0 (
set string="%string%"
echo "there is a space"
goto :EOF
)
echo "No space"
goto :EOF

REM The following does not work: findtr exit status is impropertly set
echo.%1|findstr -ric:"[\t ]"
echo.%1|findstr -ric:"[\t ]" > NUL
REM no space between %1 and pipe character
if errorlevel 1 echo "No space" && goto :EOF
echo "there is a space"