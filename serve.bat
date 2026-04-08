:: 启动mkdocs虚拟环境（注意替换为本地的anaconda3目录、虚拟环境名为hutb）
%WINDIR%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy ByPass -NoExit -Command "& 'D:\hutb\Build\dependencies\prerequisites\miniconda3\shell\condabin\conda-hook.ps1' ; conda activate hutb "; ^
mkdocs serve --livereload; 
