# LuaSocket 编译脚本(直接传导入库路径,避免 -L/-l 查找问题)
$env:PATH = 'E:\LuaYaCe\mingw64\mingw64\bin;' + $env:PATH
$build = 'E:\LuaYaCe\build_luasocket'
$src = 'E:\LuaYaCe\luasocket_src\src'
$luaInc = 'E:\LuaYaCe\wrk_tcp\3rd\lua'
$liblua = "$build\liblua53.dll.a"
$libws2 = 'E:\LuaYaCe\mingw64\mingw64\x86_64-w64-mingw32\lib\libws2_32.a'
$log = "$build\build.log"
if (-not (Test-Path "$build\socket")) { New-Item -ItemType Directory -Path "$build\socket" -Force | Out-Null }
if (-not (Test-Path "$build\mime")) { New-Item -ItemType Directory -Path "$build\mime" -Force | Out-Null }

Set-Location $src
"" | Out-File -FilePath $log -Encoding utf8

function AppendLog($msg) {
    Add-Content -Path $log -Value $msg
}

AppendLog "=== gcc version ==="
AppendLog (& gcc --version 2>&1 | Select-Object -First 1)
AppendLog "=== liblua53.dll.a exists: $(Test-Path $liblua) (size=$((Get-Item $liblua).Length)) ==="
AppendLog "=== libws2_32.a exists: $(Test-Path $libws2) ==="

AppendLog "=== compile socket/core.dll ==="
$err = & gcc -shared -O2 -Wall -DLUASOCKET_NODEBUG -DWINVER=0x0600 -D_WIN32_WINNT=0x0600 -I $luaInc $liblua $libws2 -o "$build\socket\core.dll" luasocket.c timeout.c buffer.c io.c auxiliar.c compat.c options.c inet.c wsocket.c except.c select.c tcp.c udp.c 2>&1
$exit1 = $LASTEXITCODE
AppendLog "socket exit=$exit1 err_lines=$($err.Count)"
if ($err) { $err | ForEach-Object { AppendLog $_ } | Select-Object -First 5 }

AppendLog "=== compile mime/core.dll ==="
$err2 = & gcc -shared -O2 -Wall -DLUASOCKET_NODEBUG -DWINVER=0x0600 -D_WIN32_WINNT=0x0600 -I $luaInc $liblua -o "$build\mime\core.dll" mime.c compat.c 2>&1
$exit2 = $LASTEXITCODE
AppendLog "mime exit=$exit2 err_lines=$($err2.Count)"
if ($err2) { $err2 | ForEach-Object { AppendLog $_ } | Select-Object -First 5 }

AppendLog "=== output dlls ==="
Get-ChildItem $build -Recurse -Filter '*.dll' | ForEach-Object { AppendLog ($_.FullName + ' : ' + $_.Length) }
