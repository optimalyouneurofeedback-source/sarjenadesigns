# Copies ONLY what the live website needs into docs/ (the folder GitHub Pages publishes).
# Product masters, ebook PDFs, Etsy files and notes in this folder are never published.
# Run after editing index.html, assets/ or the images the page uses, then commit + push.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$out = Join-Path $root 'docs'
if (Test-Path $out) { Get-ChildItem $out -Force | Where-Object { $_.Name -ne '.git' } | Remove-Item -Recurse -Force }
New-Item -ItemType Directory -Force $out | Out-Null

Copy-Item (Join-Path $root 'index.html') $out
Copy-Item (Join-Path $root 'assets') (Join-Path $out 'assets') -Recurse
Get-ChildItem (Join-Path $out 'assets') -Filter '*.bak*' | Remove-Item

# Every img/... file referenced by the page (src, href, srcset, CSS url())
$html = [IO.File]::ReadAllText((Join-Path $root 'index.html')) + [IO.File]::ReadAllText((Join-Path $root 'assets\site.css'))
# File names contain spaces, so match up to the closing quote/parenthesis rather than whitespace.
$refs = [regex]::Matches($html, '(?:\.\./)?(img/[^"''()<>]+?\.(?:png|jpe?g|webp|svg|gif|ico))') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
foreach ($r in $refs) {
  $src = Join-Path $root $r
  if (-not (Test-Path $src)) { Write-Warning "Missing image: $r"; continue }
  $dst = Join-Path $out $r
  New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
  Copy-Item $src $dst
}

[IO.File]::WriteAllText((Join-Path $out 'CNAME'), "www.sarjenadesigns.com`n")
[IO.File]::WriteAllText((Join-Path $out '.nojekyll'), '')
"Published {0} images; docs/ is {1:N1} MB" -f $refs.Count, ((Get-ChildItem $out -Recurse -File | Measure-Object Length -Sum).Sum / 1MB)
