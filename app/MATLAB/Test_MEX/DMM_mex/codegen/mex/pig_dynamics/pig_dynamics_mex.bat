@echo off
set MATLAB=C:\PROGRA~1\MATLAB\R2021b
call "C:\Program Files\MATLAB\R2021b\sys\lcc64\lcc64\mex\lcc64opts.bat"
"C:\Program Files\MATLAB\R2021b\toolbox\shared\coder\ninja\win64\ninja.exe" -t compdb cc cxx cudac > compile_commands.json
"C:\Program Files\MATLAB\R2021b\toolbox\shared\coder\ninja\win64\ninja.exe" -v %*
