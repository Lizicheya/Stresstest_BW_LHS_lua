# sproto / netpack / cjson 编译脚本(Windows DLL)
# 经验:GCC 链接时库文件必须放在源文件之后
$env:PATH = 'E:\LuaYaCe\mingw64\mingw64\bin;' + $env:PATH
$build = 'E:\LuaYaCe\build_cext'
$luaInc = 'E:\LuaYaCe\wrk_tcp\3rd\lua'
$liblua = 'E:\LuaYaCe\build_luasocket\liblua53.dll.a'
New-Item -ItemType Directory -Path $build -Force | Out-Null

function Run-Gcc {
    param($name, $argStr, $workDir)
    $errFile = "$build\$name.err"
    $outFile = "$build\$name.out"
    $p = Start-Process -FilePath 'E:\LuaYaCe\mingw64\mingw64\bin\gcc.exe' `
        -ArgumentList $argStr -WorkingDirectory $workDir `
        -RedirectStandardError $errFile -RedirectStandardOutput $outFile `
        -Wait -PassThru -NoNewWindow
    $exit = $p.ExitCode
    $errSize = if (Test-Path $errFile) { (Get-Item $errFile).Length } else { 0 }
    Write-Output "[$name] exit=$exit errsize=$errSize"
    if ($errSize -gt 0) {
        $errs = Get-Content $errFile -ErrorAction SilentlyContinue
        if ($errs) { $errs | Select-Object -First 3 | ForEach-Object { Write-Output "  $_" } }
    }
}

# === 1. sproto.dll(lsproto.c + sproto.c)==
$sprotoSrc = 'E:\LuaYaCe\wrk_tcp\lualib_src\sproto'
$argStr = "-shared -O2 -Wall -DLUASOCKET_NODEBUG -I `"$luaInc`" -I `"$sprotoSrc`" -o `"$build\sproto.dll`" lsproto.c sproto.c `"$liblua`""
Run-Gcc 'sproto' $argStr $sprotoSrc

# === 2. netpack.dll(lua_netpack.c)==
$netpackSrc = 'E:\LuaYaCe\wrk_tcp\lualib_src'
$argStr = "-shared -O2 -Wall -I `"$luaInc`" -o `"$build\netpack.dll`" lua_netpack.c `"$liblua`""
Run-Gcc 'netpack' $argStr $netpackSrc

# === 3. cjson.dll(lua_cjson.c + strbuf.c + fpconv.c)==
$cjsonSrc = 'E:\LuaYaCe\wrk_tcp\3rd\lua-cjson-2.1.0'
$argStr = "-shared -O2 -Wall -DNDEBUG -I `"$luaInc`" -o `"$build\cjson.dll`" lua_cjson.c strbuf.c fpconv.c `"$liblua`""
Run-Gcc 'cjson' $argStr $cjsonSrc

Write-Output "`n=== Output DLLs ==="
Get-ChildItem $build -Filter '*.dll' | ForEach-Object {
    Write-Output ("  {0} : {1} bytes" -f $_.FullName, $_.Length)
}
