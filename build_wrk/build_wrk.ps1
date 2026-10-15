# wrk.exe Windows 构建脚本
# 基于 MinGW-w64 (GCC 13.3.0) + winpthreads + winsock2
# 链接已生成的 liblua53.dll.a(动态链接 lua53.dll)

$env:PATH = 'E:\LuaYaCe\mingw64\mingw64\bin;' + $env:PATH
$build    = 'E:\LuaYaCe\build_wrk'
$src      = 'E:\LuaYaCe\wrk_tcp\wrk_src'
$luaInc   = 'E:\LuaYaCe\wrk_tcp\3rd\lua'
$liblua   = 'E:\LuaYaCe\build_luasocket\liblua53.dll.a'

New-Item -ItemType Directory -Path $build -Force | Out-Null

$cc = 'E:\LuaYaCe\mingw64\mingw64\bin\gcc.exe'
# 源文件(原 Makefile 顺序)
$sources = @(
    "$src\wrk.c",
    "$src\ae.c",
    "$src\zmalloc.c",
    "$src\net.c",
    "$src\script.c",
    "$src\stats.c",
    "$src\http_parser.c"
)

# CFLAGS:
#   -D_WIN32_WINNT=0x0600  要求 Windows Vista+(WSAPoll 支持)
#   -DHAVE_WSAPOLL         强制启用 WSAPOLL 后端
#   -D_WIN32               Windows 平台标识
#   -O2 -Wall              优化与警告
# LDFLAGS:
#   -lws2_32               Winsock2
#   -lmswsock              MSAFD
#   -lpthread              MinGW winpthreads
#   -lwinmm                timeGetTime 等
#   -llua53                动态 Lua 5.3
$cflags = "-std=gnu99 -O2 -Wall -D_WIN32_WINNT=0x0600 -D_WIN32 -I`"$luaInc`" -I`"$src`""
$ldflags = "-L `"$(Split-Path $liblua -Parent)`" -lws2_32 -lmswsock -lpthread -lwinmm -llua53 -mconsole"

$outExe = "$build\wrk.exe"
Write-Output "=== Building wrk.exe ==="
Write-Output "CFLAGS: $cflags"
Write-Output "LDFLAGS: $ldflags"
Write-Output ""

$argStr = "$cflags -o `"$outExe`" $($sources -join ' ') $ldflags -mconsole"
Write-Output "Cmd: gcc $argStr"
Write-Output ""

$errFile = "$build\build.err"
$outFile = "$build\build.out"
$p = Start-Process -FilePath $cc -ArgumentList $argStr `
    -WorkingDirectory $src -Wait -PassThru -NoNewWindow `
    -RedirectStandardError $errFile -RedirectStandardOutput $outFile

Write-Output "Exit code: $($p.ExitCode)"

if (Test-Path $errFile) {
    $err = Get-Content $errFile -ErrorAction SilentlyContinue
    if ($err) {
        Write-Output "`n=== Errors/Warnings ==="
        $err | ForEach-Object { Write-Output "  $_" }
    }
}

if (Test-Path $outExe) {
    Write-Output "`n=== Output ==="
    Get-Item $outExe | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize -Wrap
} else {
    Write-Output "`nERROR: wrk.exe not produced"
}
