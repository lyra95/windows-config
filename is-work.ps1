# 회사 PC 여부를 호스트명으로 판별
$machineName = hostname
if ($LASTEXITCODE -ne 0) { throw '호스트명을 확인하지 못했습니다.' }
return ($machineName.Trim() -ieq 'SU-01119')
