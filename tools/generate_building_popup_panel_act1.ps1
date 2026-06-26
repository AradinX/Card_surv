Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$outPath = Join-Path $root "building_popup_panel_act1.png"
$parchmentPath = Join-Path $root "assets\art\ui\panels\log_panel_act1.png"
$framePath = Join-Path $root "assets\art\cards\frames\card_frame_building.png"
$hutPath = Join-Path $root "assets\art\cards\illustrations\buildings_act1_candidates\building_hut.png"
$loggingPath = Join-Path $root "assets\art\cards\illustrations\buildings_act1_candidates\building_logging_camp.png"

function New-Color([int]$a, [int]$r, [int]$g, [int]$b) {
    return [System.Drawing.Color]::FromArgb($a, $r, $g, $b)
}

function New-RoundedPath([System.Drawing.RectangleF]$rect, [single]$radius) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $radius * 2
    $path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
    $path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
    $path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
    $path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-TornPath([single]$x, [single]$y, [single]$w, [single]$h, [int]$seed) {
    $rand = [System.Random]::new($seed)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $pts = New-Object "System.Collections.Generic.List[System.Drawing.PointF]"
    $step = 28

    for ($px = $x; $px -le $x + $w; $px += $step) {
        $pts.Add([System.Drawing.PointF]::new([single]$px, [single]($y + $rand.Next(-7, 8))))
    }
    for ($py = $y; $py -le $y + $h; $py += $step) {
        $pts.Add([System.Drawing.PointF]::new([single]($x + $w + $rand.Next(-8, 9)), [single]$py))
    }
    for ($px = $x + $w; $px -ge $x; $px -= $step) {
        $pts.Add([System.Drawing.PointF]::new([single]$px, [single]($y + $h + $rand.Next(-7, 8))))
    }
    for ($py = $y + $h; $py -ge $y; $py -= $step) {
        $pts.Add([System.Drawing.PointF]::new([single]($x + $rand.Next(-8, 9)), [single]$py))
    }

    $path.AddPolygon($pts.ToArray())
    return $path
}

function Draw-RoundedFillStroke(
    [System.Drawing.Graphics]$g,
    [System.Drawing.RectangleF]$rect,
    [single]$radius,
    [System.Drawing.Brush]$fill,
    [System.Drawing.Pen]$outer,
    [System.Drawing.Pen]$inner
) {
    $path = New-RoundedPath $rect $radius
    $g.FillPath($fill, $path)
    if ($outer -ne $null) { $g.DrawPath($outer, $path) }
    if ($inner -ne $null) {
        $inset = [System.Drawing.RectangleF]::new($rect.X + 4, $rect.Y + 4, $rect.Width - 8, $rect.Height - 8)
        $innerPath = New-RoundedPath $inset ([Math]::Max(1, $radius - 4))
        $g.DrawPath($inner, $innerPath)
        $innerPath.Dispose()
    }
    $path.Dispose()
}

function Draw-GoldInset(
    [System.Drawing.Graphics]$g,
    [System.Drawing.RectangleF]$rect,
    [single]$radius,
    [System.Drawing.Brush]$fill
) {
    $shadow = New-Object System.Drawing.SolidBrush (New-Color 120 13 10 5)
    $goldDark = New-Object System.Drawing.Pen (New-Color 255 72 47 12), 5
    $gold = New-Object System.Drawing.Pen (New-Color 255 178 126 28), 3
    $goldLight = New-Object System.Drawing.Pen (New-Color 230 235 192 72), 1

    $g.FillRectangle($shadow, $rect.X + 4, $rect.Y + 5, $rect.Width, $rect.Height)
    Draw-RoundedFillStroke $g $rect $radius $fill $goldDark $gold

    $line = [System.Drawing.RectangleF]::new($rect.X + 8, $rect.Y + 8, $rect.Width - 16, $rect.Height - 16)
    $linePath = New-RoundedPath $line ([Math]::Max(1, $radius - 6))
    $g.DrawPath($goldLight, $linePath)
    $linePath.Dispose()

    $shadow.Dispose()
    $goldDark.Dispose()
    $gold.Dispose()
    $goldLight.Dispose()
}

function Draw-Noise(
    [System.Drawing.Bitmap]$bmp,
    [System.Drawing.Rectangle]$rect,
    [int]$seed,
    [int]$count,
    [int]$alpha,
    [System.Drawing.Color]$color
) {
    $rand = [System.Random]::new($seed)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($alpha, $color))
    for ($i = 0; $i -lt $count; $i++) {
        $x = $rand.Next($rect.Left, $rect.Right)
        $y = $rand.Next($rect.Top, $rect.Bottom)
        $s = $rand.Next(1, 4)
        $g.FillRectangle($brush, $x, $y, $s, $s)
    }
    $brush.Dispose()
    $g.Dispose()
}

function Draw-Rivets([System.Drawing.Graphics]$g, [single]$x, [single]$y, [single]$w, [single]$h) {
    $dark = New-Object System.Drawing.SolidBrush (New-Color 255 48 30 8)
    $gold = New-Object System.Drawing.SolidBrush (New-Color 255 183 132 30)
    $light = New-Object System.Drawing.SolidBrush (New-Color 210 244 201 77)
    $x2 = [single]($x + $w)
    $y2 = [single]($y + $h)
    $positions = @(
        @($x, $y), @($x2, $y), @($x, $y2), @($x2, $y2)
    )
    foreach ($p in $positions) {
        $cx = [single]$p[0]
        $cy = [single]$p[1]
        $g.FillEllipse($dark, $cx - 8, $cy - 6, 18, 18)
        $g.FillEllipse($gold, $cx - 6, $cy - 8, 14, 14)
        $g.FillEllipse($light, $cx - 2, $cy - 5, 4, 4)
    }
    $dark.Dispose()
    $gold.Dispose()
    $light.Dispose()
}

$bmp = [System.Drawing.Bitmap]::new(1024, 768, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$g.Clear([System.Drawing.Color]::Transparent)

$parchment = [System.Drawing.Image]::FromFile($parchmentPath)
$frame = [System.Drawing.Image]::FromFile($framePath)
$hut = [System.Drawing.Image]::FromFile($hutPath)
$logging = [System.Drawing.Image]::FromFile($loggingPath)

$panel = [System.Drawing.RectangleF]::new(46, 32, 932, 700)
$page = [System.Drawing.RectangleF]::new(72, 58, 880, 648)
$pagePath = New-TornPath $page.X $page.Y $page.Width $page.Height 4471

# Soft transparent shadow outside the panel.
$shadowBrush = New-Object System.Drawing.SolidBrush (New-Color 110 0 0 0)
$shadowPath = New-TornPath ($page.X + 8) ($page.Y + 12) $page.Width $page.Height 4471
$g.FillPath($shadowBrush, $shadowPath)
$shadowPath.Dispose()
$shadowBrush.Dispose()

# Wood/card frame made from the building card frame texture.
$srcTop = [System.Drawing.Rectangle]::new(60, 0, 904, 120)
$srcBottom = [System.Drawing.Rectangle]::new(60, 1410, 904, 126)
$srcLeft = [System.Drawing.Rectangle]::new(0, 96, 112, 1320)
$srcRight = [System.Drawing.Rectangle]::new(912, 96, 112, 1320)
$g.DrawImage($frame, [System.Drawing.Rectangle]::new(36, 18, 954, 88), $srcTop, [System.Drawing.GraphicsUnit]::Pixel)
$g.DrawImage($frame, [System.Drawing.Rectangle]::new(36, 662, 954, 88), $srcBottom, [System.Drawing.GraphicsUnit]::Pixel)
$g.DrawImage($frame, [System.Drawing.Rectangle]::new(20, 82, 86, 592), $srcLeft, [System.Drawing.GraphicsUnit]::Pixel)
$g.DrawImage($frame, [System.Drawing.Rectangle]::new(918, 82, 86, 592), $srcRight, [System.Drawing.GraphicsUnit]::Pixel)

# Parchment page clipped to torn edges.
$state = $g.Save()
$g.SetClip($pagePath)
$g.DrawImage($parchment, [System.Drawing.Rectangle]::new(72, 58, 880, 648), 80, 70, 1370, 880, [System.Drawing.GraphicsUnit]::Pixel)
$warmWash = New-Object System.Drawing.SolidBrush (New-Color 46 77 49 18)
$g.FillRectangle($warmWash, 72, 58, 880, 648)
$warmWash.Dispose()
$g.Restore($state)

$edgePenDark = New-Object System.Drawing.Pen (New-Color 230 38 25 10), 7
$edgePenGold = New-Object System.Drawing.Pen (New-Color 210 151 111 44), 3
$g.DrawPath($edgePenDark, $pagePath)
$g.DrawPath($edgePenGold, $pagePath)
$edgePenDark.Dispose()
$edgePenGold.Dispose()

# Subtle woodland color glaze from existing building art, kept away from text zones.
$leftGlaze = New-Object System.Drawing.Imaging.ColorMatrix
$leftGlaze.Matrix33 = 0.12
$attrs = New-Object System.Drawing.Imaging.ImageAttributes
$attrs.SetColorMatrix($leftGlaze)
$g.DrawImage($hut, [System.Drawing.Rectangle]::new(63, 582, 250, 140), 0, 570, 360, 190, [System.Drawing.GraphicsUnit]::Pixel, $attrs)
$g.DrawImage($logging, [System.Drawing.Rectangle]::new(729, 80, 210, 130), 650, 0, 300, 190, [System.Drawing.GraphicsUnit]::Pixel, $attrs)
$attrs.Dispose()

$ink = New-Object System.Drawing.SolidBrush (New-Color 72 16 21 10)
$greenFill = New-Object System.Drawing.SolidBrush (New-Color 214 41 54 22)
$darkFill = New-Object System.Drawing.SolidBrush (New-Color 224 54 35 13)
$parchFill = New-Object System.Drawing.SolidBrush (New-Color 235 181 148 86)
$stripFill = New-Object System.Drawing.SolidBrush (New-Color 226 150 118 68)
$buttonFill = New-Object System.Drawing.SolidBrush (New-Color 238 31 47 20)
$blueFill = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 0, 80, 255))

# Title strip.
Draw-GoldInset $g ([System.Drawing.RectangleF]::new(150, 72, 724, 64)) 8 $darkFill

# Chroma placeholder for building image.
Draw-GoldInset $g ([System.Drawing.RectangleF]::new(105, 160, 386, 250)) 4 $blueFill

# Upper-right status and passive effects areas.
Draw-GoldInset $g ([System.Drawing.RectangleF]::new(528, 160, 382, 82)) 5 $parchFill
Draw-GoldInset $g ([System.Drawing.RectangleF]::new(528, 262, 382, 154)) 5 $parchFill

# Lower information strips.
Draw-GoldInset $g ([System.Drawing.RectangleF]::new(105, 446, 805, 44)) 4 $stripFill
Draw-GoldInset $g ([System.Drawing.RectangleF]::new(105, 504, 805, 44)) 4 $stripFill
Draw-GoldInset $g ([System.Drawing.RectangleF]::new(105, 562, 805, 44)) 4 $stripFill

# Three large bottom action buttons.
Draw-GoldInset $g ([System.Drawing.RectangleF]::new(105, 633, 245, 58)) 6 $buttonFill
Draw-GoldInset $g ([System.Drawing.RectangleF]::new(389, 633, 245, 58)) 6 $buttonFill
Draw-GoldInset $g ([System.Drawing.RectangleF]::new(673, 633, 245, 58)) 6 $buttonFill

# Non-semantic ornamentation: studs, scratches, and ink shadows only.
Draw-Rivets $g 122 178 350 214
Draw-Rivets $g 548 181 342 42
Draw-Rivets $g 548 285 342 108
Draw-Rivets $g 124 650 774 24

$scratchPen = New-Object System.Drawing.Pen (New-Color 70 56 39 15), 1
$highlightPen = New-Object System.Drawing.Pen (New-Color 80 231 194 109), 1
$rand = [System.Random]::new(829)
foreach ($i in 0..54) {
    $x = $rand.Next(96, 915)
    $y = $rand.Next(88, 682)
    $len = $rand.Next(10, 58)
    $g.DrawLine($scratchPen, $x, $y, $x + $len, $y + $rand.Next(-2, 3))
}
foreach ($i in 0..28) {
    $x = $rand.Next(86, 928)
    $y = $rand.Next(66, 704)
    $g.DrawLine($highlightPen, $x, $y, $x + $rand.Next(8, 32), $y)
}
$scratchPen.Dispose()
$highlightPen.Dispose()

# Darken frame recesses and add subtle page noise without touching the blue key area.
$vignettePath = New-RoundedPath ([System.Drawing.RectangleF]::new(62, 48, 900, 668)) 18
$vignettePen = New-Object System.Drawing.Pen (New-Color 95 0 0 0), 18
$g.DrawPath($vignettePen, $vignettePath)
$vignettePen.Dispose()
$vignettePath.Dispose()

$g.Dispose()

Draw-Noise $bmp ([System.Drawing.Rectangle]::new(72, 58, 880, 648)) 771 6500 22 ([System.Drawing.Color]::FromArgb(59, 39, 17))
Draw-Noise $bmp ([System.Drawing.Rectangle]::new(36, 18, 954, 732)) 772 2500 28 ([System.Drawing.Color]::FromArgb(226, 172, 46))

# Restore the placeholder after all noise and glazes so it remains flat RGB 0,80,255.
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.FillRectangle($blueFill, 112, 167, 372, 236)
$g.Dispose()

$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)

$pagePath.Dispose()
$blueFill.Dispose()
$buttonFill.Dispose()
$stripFill.Dispose()
$parchFill.Dispose()
$darkFill.Dispose()
$greenFill.Dispose()
$ink.Dispose()
$hut.Dispose()
$logging.Dispose()
$frame.Dispose()
$parchment.Dispose()
$bmp.Dispose()

Write-Output $outPath
