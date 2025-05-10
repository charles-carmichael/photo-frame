#!/bin/bash

# gather basic settings
echo "Starting PhotoFrame setup..."
if [ -z "$PHOTO_FRAME" ]; then PHOTO_FRAME="$HOME/photo-frame"; fi
if [ -z "$PF_ALBUM_ID" ]; then read -r -p "Enter the iCloud album id: " PF_ALBUM_ID; fi
if [ -z "$PF_ALBUM_DIR" ]; then PF_ALBUM_DIR="$PHOTO_FRAME/photos"; fi
if [ -z "$PF_ALBUM_MAX" ]; then PF_ALBUM_MAX="8640"; fi
if [ -z "$PF_AUTOSTART_TIMER" ]; then PF_AUTOSTART_TIMER="1"; fi
if [ -z "$PF_SLIDESHOW_DELAY" ]; then PF_SLIDESHOW_DELAY="5"; fi
if [ -z "$PF_RES_X" ]; then PF_RES_X=$(fbset -s | grep mode | head -1 | cut -d '"' -f 2 | cut -d 'x' -f 1); fi
if [ -z "$PF_RES_Y" ]; then PF_RES_Y=$(fbset -s | grep mode | head -1 | cut -d '"' -f 2 | cut -d 'x' -f 2); fi

# export environment variables, but don't overwrite existing values
echo "Saving configuration values..."
if ! grep -q "^export PHOTO_FRAME=" ~/.bashrc; then echo "export PHOTO_FRAME=\"$PHOTO_FRAME\"" >> ~/.bashrc; fi
if ! grep -q "^export PF_ALBUM_ID=" ~/.bashrc; then echo "export PF_ALBUM_ID=\"$PF_ALBUM_ID\"" >> ~/.bashrc; fi
if ! grep -q "^export PF_ALBUM_DIR=" ~/.bashrc; then echo "export PF_ALBUM_DIR=\"$PF_ALBUM_DIR\"" >> ~/.bashrc; fi
if ! grep -q "^export PF_ALBUM_MAX=" ~/.bashrc; then echo "export PF_ALBUM_MAX=\"$PF_ALBUM_MAX\"" >> ~/.bashrc; fi
if ! grep -q "^export PF_AUTOSTART_TIMER=" ~/.bashrc; then echo "export PF_AUTOSTART_TIMER=\"$PF_AUTOSTART_TIMER\"" >> ~/.bashrc; fi
if ! grep -q "^export PF_SLIDESHOW_DELAY=" ~/.bashrc; then echo "export PF_SLIDESHOW_DELAY=\"$PF_SLIDESHOW_DELAY\"" >> ~/.bashrc; fi
if ! grep -q "^export PF_RES_X=" ~/.bashrc; then echo "export PF_RES_X=\"$PF_RES_X\"" >> ~/.bashrc; fi
if ! grep -q "^export PF_RES_Y=" ~/.bashrc; then echo "export PF_RES_Y=\"$PF_RES_Y\"" >> ~/.bashrc; fi
# shellcheck disable=SC1090
source ~/.bashrc

# install packages
echo "Installing packages..."
sudo apt-get -qq install -y feh xautolock

# create program directory, download resources
echo "Downloading resources..."
mkdir -p "$PF_ALBUM_DIR"
curl -s -o "$PHOTO_FRAME/icon.png" https://raw.githubusercontent.com/charles-carmichael/photo-frame/main/icon.png
curl -s -o "$PHOTO_FRAME/sync_photos.py" https://raw.githubusercontent.com/charles-carmichael/photo-frame/main/sync_photos.py
curl -s -o "$PHOTO_FRAME/README.md" https://raw.githubusercontent.com/charles-carmichael/photo-frame/main/README.md

# create autostart file
echo "Creating autostart file..." 
mkdir -p ~/.config/lxsession/LXDE-pi
cat > EOF ~/.config/lxsession/LXDE-pi/autostart << EOF
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
@xautolock -time $PF_AUTOSTART_TIMER -locker "$PHOTO_FRAME/start.sh"
EOF

# create screensaver script
echo "Creating screensaver script..."
cat > ~/photo-frame/start.sh << EOF
#!/bin/bash
pkill -f feh
feh --fullscreen --slideshow-delay $PF_SLIDESHOW_DELAY --reload 3600 --hide-pointer --randomize "$PF_ALBUM_DIR"
EOF

# create desktop shortcut
echo "Creating desktop shortcut..."
cat > ~/Desktop/PhotoFrame.desktop << EOF
[Desktop Entry]
Name=PhotoFrame
Comment=iCloud Shared Album Slideshow
Exec=$PHOTO_FRAME/start.sh
Type=Application
Terminal=false
Icon=$PHOTO_FRAME/icon.png
EOF

# execute initial photo sync
echo "Starting initial photo sync..."
python3 "$PHOTO_FRAME/sync_photos.py"

# clean up
echo "Done. Photo Frame will auto-launch after 1 minute of inactivity"
