#!/bin/bash

# gather basic settings
echo "Starting PhotoFrame setup..."
if [ -z "$PHOTO_FRAME" ]; then PHOTO_FRAME="$HOME/photo-frame"; export PHOTO_FRAME; fi
if [ -z "$PF_ALBUM_ID" ]; then read -r -p "Enter the iCloud album id: " PF_ALBUM_ID; export PF_ALBUM_ID; fi
if [ -z "$PF_ALBUM_DIR" ]; then PF_ALBUM_DIR="$PHOTO_FRAME/photos"; export PF_ALBUM_DIR; fi
if [ -z "$PF_ALBUM_MAX" ]; then PF_ALBUM_MAX="8640"; export PF_ALBUM_MAX; fi
if [ -z "$PF_AUTOSTART_TIMER" ]; then PF_AUTOSTART_TIMER="1"; export PF_AUTOSTART_TIMER; fi
if [ -z "$PF_SLIDESHOW_DELAY" ]; then PF_SLIDESHOW_DELAY="5"; export PF_SLIDESHOW_DELAY; fi
if [ -z "$PF_RES_X" ]; then PF_RES_X=$(fbset -s | grep mode | head -1 | cut -d '"' -f 2 | cut -d 'x' -f 1); export PF_RES_X; fi
if [ -z "$PF_RES_Y" ]; then PF_RES_Y=$(fbset -s | grep mode | head -1 | cut -d '"' -f 2 | cut -d 'x' -f 2); export PF_RES_Y; fi

# create custom env
echo "Creating environment..."
cat > "$PHOTO_FRAME/.env" << EOF
export PHOTO_FRAME="$PHOTO_FRAME"
export PF_ALBUM_ID="$PF_ALBUM_ID"
export PF_ALBUM_DIR="$PF_ALBUM_DIR"
export PF_ALBUM_MAX="$PF_ALBUM_MAX"
export PF_AUTOSTART_TIMER="$PF_AUTOSTART_TIMER"
export PF_SLIDESHOW_DELAY="$PF_SLIDESHOW_DELAY"
export PF_RES_X="$PF_RES_X"
export PF_RES_Y="$PF_RES_Y"
EOF
if ! grep -q "^\. $PHOTO_FRAME/\.env" ~/.bashrc; then echo ". $PHOTO_FRAME/.env" >> ~/.bashrc; fi

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
cat > ~/.config/labwc/autostart << EOF
swayidle -w timeout 60 "$PHOTO_FRAME/start.sh"
EOF

# create screensaver script
echo "Creating screensaver script..."
cat > ~/photo-frame/start.sh << EOF
#!/bin/bash
pkill -f feh
sleep 5
feh --fullscreen --slideshow-delay $PF_SLIDESHOW_DELAY --reload 3600 --hide-pointer --randomize "$PF_ALBUM_DIR"
EOF
chmod +x "$PHOTO_FRAME/start.sh"

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
chmod +x ~/Desktop/PhotoFrame.desktop
pcmanfm --reconfigure  # refresh so icon shows up

# execute initial photo sync
echo "Starting initial photo sync..."
python3 "$PHOTO_FRAME/sync_photos.py"

# add crontab entry for nightly photo sync
echo "Updating cron sync schedule..."
CRON_SYNC="0 3 * * * /bin/bash -c 'source $PHOTO_FRAME/.env && python3 $PHOTO_FRAME/sync_photos.py > $PHOTO_FRAME/sync_photos.log 2>&1'"
CRON_START="5 3 * * * $PHOTO_FRAME/start.sh > $PHOTO_FRAME/start.log 2>&1"
crontab -l 2>/dev/null > temp_cron || true
grep -F "$CRON_SYNC" temp_cron >/dev/null || echo "$CRON_SYNC" >> temp_cron
grep -F "$CRON_START" temp_cron >/dev/null || echo "$CRON_START" >> temp_cron
crontab temp_cron
rm temp_cron

# clean up
echo "Done. Photo Frame will auto-launch after 1 minute of inactivity."
