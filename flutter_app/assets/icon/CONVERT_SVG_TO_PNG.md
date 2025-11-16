# Converting SVG to PNG for App Icon

The app icon has been created as an SVG file (`icon.svg`). You need to convert it to PNG format for use with Flutter launcher icons.

## Option 1: Online Converter (Easiest)
1. Go to https://cloudconvert.com/svg-to-png or https://convertio.co/svg-png/
2. Upload `assets/icon/icon.svg`
3. Set output size to **1024x1024 pixels**
4. Download the PNG file
5. Replace `assets/icon/icon.png` with the downloaded file

## Option 2: Install ImageMagick (Command Line)
1. Download ImageMagick from https://imagemagick.org/script/download.php
2. Install it
3. Run this command from the `flutter_app` directory:
   ```powershell
   magick assets/icon/icon.svg -resize 1024x1024 assets/icon/icon.png
   ```

## Option 3: Install Inkscape (Free Vector Editor)
1. Download Inkscape from https://inkscape.org/release/
2. Install it
3. Open `assets/icon/icon.svg` in Inkscape
4. Go to File > Export PNG Image
5. Set size to 1024x1024 pixels
6. Export as `assets/icon/icon.png`

## Option 4: Use a Graphics Editor
- Open the SVG in Adobe Illustrator, GIMP, or any graphics editor
- Export as PNG at 1024x1024 pixels
- Save as `assets/icon/icon.png`

## After Converting
Once you have the PNG file, regenerate the launcher icons:
```bash
cd flutter_app
flutter pub run flutter_launcher_icons
```

This will generate all the required icon sizes for Android and iOS.

