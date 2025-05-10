# Photo Frame

_iCloud Shared Album Photo Frame, Designed for Raspberry Pi_

---

I didn't love any existing photo frame projects. MagicMirror is cool, but includes so much extra functionality I didn't need. Also, most of the iCloud Shared Album projects are broken for whatever reason.

### iCloud Shared Album Setup

- Create a new **Shared Album** in the Photos app.
- In the new shared album settings, enable **Public Website** to get a public view-only URL.
- Note the **Album ID**, it's the last element of the URL, starting with "#". 

### Raspberry Pi Setup

A script called `install.py` automatically handles the configuration of your photo frame. Execute it on your pi with:

```bash
curl -sL https://raw.githubusercontent.com/charles-carmichael/main/install.sh | bash
```

This will do the following: 

- Gathers basic configuration settings
- Installs required packages
- Creates program directory, downloads resources
- Creates local autostart resources, shell scripts, shortcuts
- Executes initial photo album download (this can take a while)

### Notes
- To exit the photo frame and go back to desktop, press Escape. The photo frame will resume after one minute of inactivity.
- The following settings are stored in environment variables if you want to change them: 
  - `PHOTO_FRAME`: the photo frame program data directory (default: `~/photo-frame`)
  - `PF_ALBUM_ID`: the public shared album url id (starts with "#")
  - `PF_ALBUM_DIR`: the local directory to store photos (default: `~/photo-frame/photos`)
  - `PF_ALBUM_MAX`: the maximum number of photos to keep (default: the 8640 most recently added photos)
  - `PF_AUTOSTART_TIMER`: the number of minutes of inactivity to wait before starting the photo frame
  - `PF_SLIDESHOW_DELAY`: the number of seconds to display each photo
  - `PF_RES_X`: the desired photo width (default: resolution width)
  - `PF_RES_Y`: the desired photo height (default: resolution height)
- Some photos aren't downloading for unknown reasons, more troubleshooting required.
- Don't forget to install a remote support agent like Raspberry Pi Connect to help your family/friends when stuff breaks.
