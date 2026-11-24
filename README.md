

# Savee Animation Study

A Flutter project that brings the image browsing animations from the original Savee mobile app to life. I focused on the small details that make opening an image and returning to the feed feel smooth.

## Demo

<div>
  <div><video controls src="https://github.com/user-attachments/assets/ec0223a9-4c8b-40f4-ab4c-4434a605dd60" muted="false"></video></div>
</div>

<!-- For GitHub's inline video preview, upload record.MP4 through the GitHub editor and replace the video src above with the attachment URL. -->

## What I focused on

### Animation from the original app

Tapping an image expands it into the detail view while the feed moves back. The background, rounded corners, and image move together. Closing the view brings the image back to its place in the feed, even after scrolling.

### Lower memory use

The app matches each image's size in physical pixels to its displayed width while keeping the original image ratio. This reduces bitmap memory, the memory needed to hold the image's pixels. Small feed images use fewer pixels, and the detail view prepares a larger version when opened.

The feed passes the image bytes already in memory to the detail view. Reusing these bytes avoids loading the same image file twice when moving from feed to detail. The detail view uses those same bytes to prepare the larger image.

The image's width and height are known before it loads, so each card already has the right shape. Larger images in the detail view are released when that view closes.
