param(
    # Directory that is filled with the payload (Flutter release output + logo + VC runtime + msix helper)
    [string]$PayloadDir = 'D:\inno',
    # Directory the installer is written to
    [string]$ResultDir = 'D:\inno-result',
    # Skip "SignTool=MySignTool"; required for local builds without the signing tool configured in Inno Setup
    [switch]$SkipSignTool
)

$makepri = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin\10.*\x64\makepri.exe' | Select-Object -Last 1
& $makepri.FullName new /pr support\build\msix\content /cf support\build\msix\priconfig.xml /mn support\build\msix\content\AppxManifest.xml /of support\build\msix\content\resources.pri /o
& 'C:\Program Files (x86)\Windows Kits\10\App Certification Kit\makeappx.exe' pack /o /d support\build\msix\content /nv /p app\windows\localsend_msix_helper.msix

cd app

fvm flutter clean
fvm flutter pub get
fvm flutter build windows

Remove-Item $PayloadDir -Force  -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $PayloadDir
Copy-Item -Path "build\windows\x64\runner\Release\*" -Destination $PayloadDir -Recurse
Copy-Item -Path "assets\packaging\logo.ico" -Destination $PayloadDir

cd ..

Copy-Item -Path "support\build\windows\x64\*" -Destination $PayloadDir -Recurse
Remove-Item $ResultDir -Force  -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $ResultDir

$innoArgs = @("/DPayloadDir=$PayloadDir", "/DResultDir=$ResultDir")
if ($SkipSignTool) {
    $innoArgs += '/DSkipSignTool'
}
iscc @innoArgs .\support\scripts\compile_windows_exe-inno.iss

Write-Output 'Generated Windows exe installer!'
