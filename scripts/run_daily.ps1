# Pipeline IMDb hằng ngày: download -> load_staging -> build_core -> swap_core

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Xác định thư mục project = thư mục chứa script này
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot
Write-Host "📂 Working dir: $ProjectRoot"

# 0) Đợi Docker Desktop sẵn sàng (tối đa ~5 phút)
Write-Host "⏳ Checking Docker Desktop readiness..."
$tries = 0
while (-not (docker info 2>$null)) {
    Start-Sleep -Seconds 10
    $tries++
    if ($tries -ge 30) { throw "❌ Docker is not available after 5 minutes." }
}
Write-Host "🐳 Docker ready."

# 0.1) Đảm bảo container postgres đang chạy
if (-not (docker ps --filter "name=imdb_pg" --filter "status=running" -q)) {
    Write-Host "🔄 Starting container: imdb_pg ..."
    docker start imdb_pg | Out-Null
}
# 0.2) pgAdmin
if (-not (docker ps --filter "name=imdb_pgadmin" --filter "status=running" -q)) {
    Write-Host "🔄 Starting container: imdb_pgadmin ..."
    docker start imdb_pgadmin | Out-Null
}

# 1) Tải & giải nén IMDb datasets (ghi đè data/unpacked/*.tsv)
Write-Host "⬇️  Step 1/4: download_imdb.py"
python scripts/download_imdb.py

# 2) Nạp STAGING (TRUNCATE rồi COPY server-side)
Write-Host "📥 Step 2/4: load_staging.py"
python scripts/load_staging.py

# 3) Build CORE (tạo *_new + index + FK)
Write-Host "🏗  Step 3/4: build_core.sql"
docker exec -i imdb_pg psql `
  -U imdb_user -d imdb -v ON_ERROR_STOP=1 `
  -f /scripts/build_core.sql

# 4) Swap CORE (atomic rename *_new -> bảng chính)
Write-Host "🔁 Step 4/4: swap_core.sql"
docker exec -i imdb_pg psql `
  -U imdb_user -d imdb -v ON_ERROR_STOP=1 `
  -f /scripts/swap_core.sql

Write-Host "✅ ✓ Daily IMDb refresh done."