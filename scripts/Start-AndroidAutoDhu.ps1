[CmdletBinding()]
param(
    [string]$Serial = 'localhost:5555',
    [ValidateRange(1024, 65535)][int]$Port = 5278,
    [string]$SdkRoot = "$env:LOCALAPPDATA\Android\Sdk",
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
$adb = Join-Path $SdkRoot 'platform-tools\adb.exe'
$dhu = Join-Path $SdkRoot 'extras\google\auto\desktop-head-unit.exe'
foreach ($toolPath in @($adb, $dhu)) {
    if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) {
        throw "필요한 도구가 없습니다: $toolPath (SDK Manager에서 Android Auto Desktop Head Unit 설치)"
    }
}
$deviceState = & $adb -s $Serial get-state
if ($LASTEXITCODE -ne 0 -or $deviceState.Trim() -ne 'device') {
    throw "ADB 장치에 연결할 수 없습니다: $Serial"
}
if ($CheckOnly) {
    Write-Output "준비 완료: ADB $Serial, DHU $dhu"
    return
}
$existing = & $adb forward --list
foreach ($line in $existing) {
    $parts = $line -split '\s+'
    if ($parts.Length -ge 3 -and $parts[1] -eq "tcp:$Port" -and
        ($parts[0] -ne $Serial -or $parts[2] -ne 'tcp:5277')) {
        throw "포트 $Port 가 다른 ADB 연결에서 사용 중입니다. -Port 로 다른 포트를 지정하세요."
    }
}
& $adb -s $Serial forward "tcp:$Port" tcp:5277
if ($LASTEXITCODE -ne 0) { throw 'ADB 포트 전달에 실패했습니다.' }
Write-Host '휴대폰 Android Auto 개발자 메뉴에서 헤드 유닛 서버를 시작하세요.'
Write-Host '음악 자동 시작을 꺼두세요. 이 스크립트는 재생 명령을 보내지 않습니다.'
Write-Host 'DHU 콘솔에 quit를 입력하면 종료됩니다. 이 터미널을 열어두세요.'
& $dhu "--adb=$Port"
if ($LASTEXITCODE -ne 0) { throw "DHU 종료 코드: $LASTEXITCODE" }
