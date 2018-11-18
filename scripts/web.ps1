#Requires -Version 5
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$root = (Resolve-Path (Join-Path $PSScriptRoot '../')).Path
$tempDir = (Join-Path $root 'web-temp')
$outDir = (Join-Path $root 'web-build')

function GenerateWebsite {
    CreateDirectories
    CopyStaticAssets
    PreprocessAllMdPageFiles
    AddTreeToDocIndexMdFiles
    ConvertAllMdFilesToHtml
}

function CreateDirectories {
    mkdir -Force $tempDir | Out-Null
    rm -Recurse "$tempDir\*"
    mkdir -Force $outDir | Out-Null
    rm -Recurse "$outDir\*"
}

function CopyStaticAssets {
    $srcAssetsDir = (Join-Path $root 'web/assets')
    cp $srcAssetsDir\* web-build\ -Recurse
}

function PreprocessAllMdPageFiles {
    $prefix = (Join-Path $root 'web/pages')
    Push-Location $prefix
    try {
        $mdFilePaths = ls -Recurse $prefix | Where-Object { $_.Extension -eq '.md' } | Select-Object -ExpandProperty 'FullName'
        foreach ($filePath in $mdFilePaths) {
            $relativePath = Resolve-Path -Relative $filePath

            # read the unprocessed markdown
            $md = [System.IO.File]::ReadAllText($filePath)

            # generate the breadcrumb bar
            $crumb = ''
            $parent = [System.IO.Path]::GetDirectoryName($filePath)
            $parentRelativePath = Resolve-Path -Relative $parent

            if ([System.IO.Path]::GetFileName($filePath) -eq 'index.md') {
                $parent = [System.IO.Path]::GetDirectoryName($parent)
            }

            while ($parent.Length -gt $prefix.Length) {
                $title = GetTitle -MdFilePath (Join-Path $parent 'index.md') -AllowMarkdown $true
                if ($crumb -ne '') {
                    $crumb = ' <span class="crumb-separator">»</span> ' + $crumb
                }
                $crumb = '[' + $title + '](' + $parentRelativePath.Substring(1).Replace('\','/') + '/index.html)' + $crumb
                $parent = [System.IO.Path]::GetDirectoryName($parent)
            }

            if ($crumb -ne '') {
                $md = '<nav><p id="crumb">' + $crumb + '</p></nav>' + "`n`n" + $md
            }

            # generate railroad diagrams
            #TODO

            # write the processed markdown
            $objFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath((Join-Path $tempDir $relativePath))
            mkdir ([System.IO.Path]::GetDirectoryName($objFilePath)) -Force | Out-Null
            [System.IO.File]::WriteAllText($objFilePath,$md)
        }
    } finally {
        Pop-Location
    }
}

function AddTreeToDocIndexMdFiles {
    $indexMdPaths = ls $tempDir -Recurse | Where-Object { $_.Name -eq 'index.md' } | Select-Object -ExpandProperty 'FullName'
    foreach ($filePath in $indexMdPaths) {
        $dirPath = [System.IO.Path]::GetDirectoryName($filePath)
        # don't put a tree in the root index.html
        if ($dirPath -eq $tempDir) {
            continue
        }
        $lines = GetTreeMdLines -DirPath $dirPath -RootPrefix $tempDir -Indent ''
        $md = [System.IO.File]::ReadAllText($filePath)
        $md += "`n`n" + '<div id="toc">' + "`n"
        $md += [System.String]::Join("`n",$lines)
        $md += "`n</div>`n"
        [System.IO.File]::WriteAllText($filePath,$md)
    }
}

function GetTreeMdLines {
    param(
        [string]$DirPath,
        [string]$RootPrefix,
        [string]$Indent
    )

    $lines = @()
    Push-Location $RootPrefix
    try {
        $subfolderPaths = ls $DirPath -Directory | Select-Object -ExpandProperty 'FullName'
        foreach ($subfolderPath in $subfolderPaths) {
            $subfolderRelativePath = Resolve-Path -Relative $subfolderPath
            $subfolderTitle = GetTitle -MdFilePath (Join-Path $subfolderPath 'index.md')
            $lines += -join ($Indent,'- [',$subfolderTitle,'](',$subfolderRelativePath.Substring(1).Replace('\','/'),')')

            $recursedLines = GetTreeMdLines -DirPath $subfolderPath -RootPrefix $RootPrefix -Indent ($Indent + '    ')
            foreach ($recursedLine in $recursedLines) {
                $lines += $recursedLine
            }
        }

        $documentFilePaths = ls $DirPath | Where-Object { $_.Extension -eq '.md' } | Select-Object -ExpandProperty 'FullName'
        foreach ($documentFilePath in $documentFilePaths) {
            $mdDocumentRelativePath = Resolve-Path -Relative $documentFilePath
            $htmlDocumentRelativePath = $mdDocumentRelativePath.Substring(0,$mdDocumentRelativePath.Length - 3) + '.html'
            if ([System.IO.Path]::GetFileName($documentFilePath) -ne 'index.md') {
                $documentTitle = GetTitle -MdFilePath $documentFilePath
                $lines += -join ($Indent,'- [',$documentTitle,'](',$htmlDocumentRelativePath.Substring(1).Replace('\','/'),')')
            }
        }
    } finally {
        Pop-Location
    }

    return $lines
}

function GetTitle {
    param(
        [string]$MdFilePath,
        [bool]$AllowMarkdown
    )

    $title = ''
    foreach ($line in [System.IO.File]::ReadAllLines($MdFilePath)) {
        if ($line.StartsWith('# ')) {
            $title = $line.Substring(2).Trim()
        }
    }

    if ($AllowMarkdown -eq $false) {
        $title = $title.Replace('`','')
    }

    return $title
}

function ConvertAllMdFilesToHtml {
    $pandocDir = (Join-Path $root 'ext/pandoc')
    $pandocExePath = (Join-Path $root 'ext/pandoc/pandoc.exe')
    $pandocZipPath = (Join-Path $root 'ext/pandoc/pandoc.zip')
    if (-not (Test-Path $pandocExePath)) {
        Expand-Archive $pandocZipPath -DestinationPath $pandocDir
    }
    $pageHtmlTemplate = [System.IO.File]::ReadAllText((Join-Path $root 'web/templates/page.html'))
    $css = '<style>' + [System.IO.File]::ReadAllText((Join-Path $root 'web/templates/style.css')) + '</style>'
    $pageHtmlTemplate = $pageHtmlTemplate.Replace('<!--CSS-->',$css)
    $mdFilePaths = ls $tempDir -Recurse | Where-Object { $_.Extension -eq '.md' } | Select-Object -ExpandProperty 'FullName'
    foreach ($mdFilePath in $mdFilePaths) {
        $directoryPath = [System.IO.Path]::GetDirectoryName($mdFilePath)
        $mdFileName = [System.IO.Path]::GetFileName($mdFilePath)
        $name = [System.IO.Path]::GetFileNameWithoutExtension($mdFileName)
        $extension = [System.IO.Path]::GetExtension($mdFileName)
        $htmlFragmentFilePath = (Join-Path $directoryPath ($name + '.html_fragment'))
        $binDirectoryPath = $directoryPath.Replace($tempDir,$outDir)
        $htmlFilePath = (Join-Path $binDirectoryPath ($name + '.html'))
        mkdir -Force ([System.IO.Path]::GetDirectoryName($htmlFilePath)) | Out-Null
        & $pandocExePath -f markdown-auto_identifiers-implicit_figures+backtick_code_blocks -t html -o "$htmlFragmentFilePath" "$mdFilePath"
        $title = GetTitle -MdFilePath $mdFilePath -AllowMarkdown $false
        $content = [System.IO.File]::ReadAllText($htmlFragmentFilePath)
        $pageHtml = $pageHtmlTemplate.Replace('<!--TITLE-->',$title).Replace('<!--CONTENT-->',$content)
        [System.IO.File]::WriteAllText($htmlFilePath,$pageHtml)
        Write-Output $htmlFilePath
    }
}

GenerateWebsite
