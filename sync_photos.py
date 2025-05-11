import os

import requests
from PIL import Image
from PIL import ImageFilter


# load settings
ALBUM_URL = f"https://www.icloud.com/sharedalbum/{os.getenv('PF_ALBUM_ID')}"
ALBUM_DIR = os.getenv("PF_ALBUM_DIR")
ALBUM_MAX = int(os.getenv("PF_ALBUM_MAX"))
RES_X = int(os.getenv("PF_RES_X"))
RES_Y = int(os.getenv("PF_RES_Y"))


def fetch_album_host(album_id):
    """Fetch the album metadata from iCloud's API."""
    api_url = f"https://p23-sharedstreams.icloud.com/{album_id}/sharedstreams/webstream"
    headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
    }
    payload = {"streamCsn": ""}  # empty payload seems to work for public albums
    response = requests.post(api_url, headers=headers, json=payload)
    response.raise_for_status()  # raise an error if the request fails
    return response.json().get('X-Apple-MMe-Host')


def sync_photos(album_url, output_dir):
    """Download all photos from the album data to the specified directory."""
    # determine where the photos can be pulled from
    album_id = album_url.split("#")[-1]
    album_host = fetch_album_host(album_id)
    base_url = f"https://{album_host}/{album_id}/sharedstreams"

    # get the current photo list by guid
    print('Getting photo list...')
    metadata_url = f"{base_url}/webstream"
    r = requests.post(metadata_url, data='{"streamCtag":null}')
    r.raise_for_status()
    stream_data = r.json()
    photos_metadata = stream_data.get('photos')

    # make sure photo metadata was returned
    if not photos_metadata:
        print("No photos found. Exiting...")
        exit()

    # sort photos by batchDateCreated and only keep the most recent
    sorted_photo_metadata = sorted(
        photos_metadata,
        key=lambda metadata: metadata.get("batchDateCreated", "0"),  # fallback to "0" if missing
        reverse=True  # newest first
    )
    recent_photos = sorted_photo_metadata[:ALBUM_MAX]  # limit to album_max

    # make a list of appropriate photo guids and current filenames
    photo_ids = list()
    current_files = list()
    for i, photo in enumerate(recent_photos):
        # pick the highest quality derivative (usually the last one)
        derivatives = photo.get("derivatives", {})
        if not derivatives:
            continue
        best_derivative = sorted(derivatives.items(), key=lambda derivative: int(derivative[1]["fileSize"]))[-1]
        photo_guid = photo.get("photoGuid")
        photo_checksum = best_derivative[1]["checksum"]
        # check if the photo has already been downloaded
        filename = f"{photo_guid}_{photo_checksum[:8]}.jpg"
        current_files.append(filename)
        if not os.path.exists(os.path.join(output_dir, filename)):
            photo_ids.append((photo_guid, photo_checksum))
    print(f"Found {len(photo_ids)} new photo{'s' if len(photo_ids) != 1 else ''}")

    # download each photo
    photos_url = f"{base_url}/webasseturls"
    for guid, checksum in photo_ids:
        # get the download url
        print(f"Processing photo {guid}/{checksum}...")
        payload = {"photoGuids": [guid]}
        response = requests.post(photos_url, json=payload)
        url_data = response.json()
        url_info = url_data["items"].get(checksum, {})
        if not url_info:
            print(f"Warning: No URL found for photo {guid} (checksum: {checksum})")
            continue
        download_url = f"https://{url_info['url_location']}{url_info['url_path']}"

        # download the photo
        photo_download = requests.get(download_url, stream=True)
        photo_download.raise_for_status()

        # write the photo to disk
        filepath = os.path.join(output_dir, f"{guid}_{checksum[:8]}.jpg")
        with open(filepath, "wb") as f:
            for chunk in photo_download.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f"Downloaded: {filepath}")

    # remove old photos
    old_files = list()
    for existing_file in os.listdir(output_dir):
        if existing_file not in current_files:
            old_files.append(existing_file)
    print(f"Deleting {len(old_files)} old file{'s' if len(old_files) != 1 else ''}...")
    for x in old_files:
        os.remove(os.path.join(output_dir, x))


def resize_photos(target_x, target_y):
    """Resize, extend, and blur photos to match the desired resolution."""
    target_ar = target_x / target_y
    for file in os.listdir(ALBUM_DIR):
        # load the existing image
        image = Image.open(os.path.join(ALBUM_DIR, file))
        x, y = image.size
        ar = x / y

        # check if size is already appropriate
        if (x, y) == (target_x, target_y):
            continue

        # resize the image and blur any extensions
        print(f'Resizing {file}...')
        new_image = image.resize((target_x, target_y))
        new_image = new_image.filter(ImageFilter.GaussianBlur(radius=70))
        if ar > target_ar:
            # resize the original image to fit the screen width
            new_height = int((target_x / x) * y)
            image = image.resize((target_x, new_height))
            paste_x = 0
            paste_y = int((target_y - new_height) / 2)
        else:
            # resize the original image to fit the screen height
            new_width = int((target_y / y) * x)
            image = image.resize((new_width, target_y))
            paste_x = int((target_x - new_width) / 2)
            paste_y = 0
        new_image.paste(image, (paste_x, paste_y))
        new_image.save(os.path.join(ALBUM_DIR, file))


def main():
    # sync the photos to the output dir
    sync_photos(ALBUM_URL, ALBUM_DIR)

    # resize and extend photos for specific screen
    resize_photos(RES_X, RES_Y)


if __name__ == '__main__':
    main()
