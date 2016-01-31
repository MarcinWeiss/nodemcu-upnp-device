for %%i in (*.lua) do python luatool.py --port COM6 --src %%i --dest %%i --verbose
for %%i in (*.xml) do python luatool.py --port COM6 --src %%i --dest %%i --verbose
for %%i in (*.png) do python luatool.py --port COM6 --src %%i --dest %%i --verbose
for %%i in (*.html) do python luatool.py --port COM6 --src %%i --dest %%i --verbose
for %%i in (*.ico) do python luatool.py --port COM6 --src %%i --dest %%i --verbose