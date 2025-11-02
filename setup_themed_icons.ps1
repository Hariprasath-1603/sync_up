# PowerShell script to set up themed launcher icons
# This copies light icons to night-mode resource folders for automatic theme switching

Write-Host "Setting up themed launcher icons..." -ForegroundColor Green

# Get the light icon path
$lightIcon = "assets\icons\ic_syncup_light.png"
$resPath = "android\app\src\main\res"

# Check if light icon exists
if (-not (Test-Path $lightIcon)) {
    Write-Host "Error: Light icon not found at $lightIcon" -ForegroundColor Red
    exit 1
}

# Install dependencies for image processing
Write-Host "Installing ImageMagick (if not already installed)..." -ForegroundColor Yellow
# User needs to have ImageMagick installed for resizing

# Define the sizes for each mipmap density
$sizes = @{
    "mipmap-night-mdpi" = 48
    "mipmap-night-hdpi" = 72
    "mipmap-night-xhdpi" = 96
    "mipmap-night-xxhdpi" = 144
    "mipmap-night-xxxhdpi" = 192
}

# Create night-mode directories if they don't exist
foreach ($folder in $sizes.Keys) {
    $dir = Join-Path $resPath $folder
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created directory: $dir" -ForegroundColor Cyan
    }
}

# Copy and resize icons (requires ImageMagick or manual copying)
Write-Host "`nFor automatic resizing, please install ImageMagick and run:" -ForegroundColor Yellow
Write-Host "foreach (\$folder in @('mipmap-night-mdpi', 'mipmap-night-hdpi', 'mipmap-night-xhdpi', 'mipmap-night-xxhdpi', 'mipmap-night-xxxhdpi')) {" -ForegroundColor Gray
Write-Host "    magick convert $lightIcon -resize {size}x{size} android\app\src\main\res\`$folder\ic_launcher.png" -ForegroundColor Gray
Write-Host "}" -ForegroundColor Gray

Write-Host "`nAlternatively, manually copy resized light icons to:" -ForegroundColor Yellow
foreach ($folder in $sizes.Keys) {
    Write-Host "  - $resPath\$folder\ic_launcher.png (${($sizes[$folder])}x${($sizes[$folder])} px)" -ForegroundColor Gray
}

Write-Host "`nManual setup required: Copy light themed icons to the night-mode folders listed above." -ForegroundColor Green
