@SETLOCAL
@SET PATHEXT=%PATHEXT:;.JS;=;%
..\Build\Windows\node\node  "..\Build\node_modules\typescript\bin\tsc" %*
