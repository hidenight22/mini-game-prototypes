param(
    [string]$PrototypeDir = "prototypes",
    [string]$OutputPath = "index.html"
)

$ErrorActionPreference = "Stop"

function ConvertTo-Title {
    param([string]$FileName)

    $name = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    return $name -replace "[-_]+", " "
}

function Get-PrototypeTitle {
    param([System.IO.FileInfo]$File)

    $fallback = ConvertTo-Title $File.Name
    try {
        $content = [System.IO.File]::ReadAllText($File.FullName, [System.Text.Encoding]::UTF8)
        $match = [regex]::Match($content, "<title>\s*(.*?)\s*</title>", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($match.Success) {
            $title = [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value.Trim())
            if (-not [string]::IsNullOrWhiteSpace($title)) {
                return $title
            }
        }
    } catch {
    }
    return $fallback
}

$root = Split-Path -Parent $PSScriptRoot
$prototypePath = Join-Path $root $PrototypeDir
$outputFile = Join-Path $root $OutputPath

if (-not (Test-Path -LiteralPath $prototypePath)) {
    New-Item -ItemType Directory -Path $prototypePath | Out-Null
}

$games = @(Get-ChildItem -LiteralPath $prototypePath -Filter "*.html" -File |
    Sort-Object Name |
    ForEach-Object {
        [PSCustomObject]@{
            Title = Get-PrototypeTitle $_
            Href = "./$PrototypeDir/$([System.Uri]::EscapeDataString($_.Name))"
        }
    })

$items = if ($games.Count -gt 0) {
    ($games | ForEach-Object {
        @"
    <a class="game-link" href="$($_.Href)">
      <span>$([System.Net.WebUtility]::HtmlEncode($_.Title))</span>
      <span>&#50676;&#44592;</span>
    </a>
"@
    }) -join "`n"
} else {
    '    <p class="empty">&#50500;&#51649; &#46321;&#47197;&#46108; &#54532;&#47196;&#53664;&#53440;&#51077;&#51060; &#50630;&#49845;&#45768;&#45796;.</p>'
}

$html = @"
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>&#48120;&#45768;&#44172;&#51076; &#54532;&#47196;&#53664;&#53440;&#51077;</title>
  <style>
    :root {
      color-scheme: light;
      --ink: #17202a;
      --muted: #5d6972;
      --bg: #eef3f2;
      --panel: #ffffff;
      --line: #c8d6d2;
      --accent: #1f6f8b;
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      padding: 22px;
      background: var(--bg);
      color: var(--ink);
      font-family: "Malgun Gothic", "Apple SD Gothic Neo", system-ui, sans-serif;
    }

    main {
      width: min(680px, 100%);
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 22px;
      box-shadow: 0 14px 42px rgba(23, 32, 42, 0.16);
    }

    h1 {
      margin: 0 0 8px;
      font-size: 28px;
      letter-spacing: 0;
    }

    p {
      margin: 0 0 18px;
      color: var(--muted);
      line-height: 1.55;
    }

    .list {
      display: grid;
      gap: 10px;
    }

    .game-link {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
      width: 100%;
      min-height: 58px;
      padding: 14px 16px;
      border: 1px solid #9fb6b0;
      border-radius: 8px;
      background: #f8fbfb;
      color: var(--ink);
      text-decoration: none;
      font-weight: 800;
    }

    .game-link:hover {
      border-color: var(--accent);
      color: var(--accent);
    }

    .empty {
      padding: 14px 16px;
      border: 1px dashed var(--line);
      border-radius: 8px;
      background: #f8fbfb;
    }

    small {
      display: block;
      margin-top: 14px;
      color: var(--muted);
      line-height: 1.45;
    }
  </style>
</head>
<body>
  <main>
    <h1>&#48120;&#45768;&#44172;&#51076; &#54532;&#47196;&#53664;&#53440;&#51077;</h1>
    <p>&#47553;&#53356; &#53580;&#49828;&#53944;&#50857; &#44277;&#44060; &#54532;&#47196;&#53664;&#53440;&#51077; &#47785;&#47197;&#51077;&#45768;&#45796;.</p>
    <div class="list">
$items
    </div>
    <small>&#49352; HTML &#54028;&#51068;&#51008; <code>prototypes/</code> &#54260;&#45908;&#50640; &#45347;&#44256; <code>tools/update-index.ps1</code>&#51012; &#49892;&#54665;&#54616;&#47732; &#47785;&#47197;&#50640; &#48152;&#50689;&#46121;&#45768;&#45796;.</small>
  </main>
</body>
</html>
"@

[System.IO.File]::WriteAllText($outputFile, $html, [System.Text.UTF8Encoding]::new($false))
Write-Host "Updated $OutputPath with $($games.Count) prototype(s)."
