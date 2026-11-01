param([string]$ProjectRoot='C:\Users\DELL\Dropbox\PC\Downloads\HQT')
$ErrorActionPreference='Stop'
$audit='C:\Users\DELL\.codex\.chatgpt-projects\g-p-6acae3b9498c8191b1de5edb9da42229\audit_hqt_sql.ps1'
if(-not (Test-Path -LiteralPath $audit)){ throw 'Không tìm thấy audit_hqt_sql.ps1' }
Write-Host '=== KIỂM TRA CÚ PHÁP TẤT CẢ FILE SQL ==='
& $audit -Mode Parse
Write-Host '=== KIỂM TRA CHỈ ĐỌC: BÁO CÁO / QUYỀN / ĐỒNG BỘ ==='
& $audit -Mode ReadOnly
Write-Host 'Hoàn tất: không có thao tác INSERT/UPDATE/DELETE trong bước kiểm thử này.'
