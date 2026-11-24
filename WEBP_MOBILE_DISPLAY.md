# WebP for Mobile Image Display

Notes on why WebP is used for images in mobile apps (e.g. list screens), and what it does and doesn't change.

## 1. WebP reduces network transfer

WebP files are smaller than PNG (and usually JPEG) at similar visual quality.

- Faster downloads
- Less mobile data used
- Better scrolling experience in lists that load many images at once

## 2. Every format must be decoded to a bitmap

WebP, PNG, JPEG, and AVIF are all compressed. Before an image can be drawn, the device decodes it into a raw bitmap.

```
download file -> decode to bitmap -> upload to GPU -> display
   (small)         (CPU work)        (large in memory)
```

- Decoding costs some CPU time. This applies to **every** format, not only WebP.
- **Memory depends on resolution, not on file size or format.** Decoded size is roughly:

  ```
  width x height x 4 bytes
  ```

- Higher display resolution means more memory. A smaller file does **not** mean less RAM.
- Resize images on the server (or downsample on the device) to the size actually displayed.

### File size vs decoded memory (2000x2000 example)

| | Size | Depends on |
|---|---|---|
| WebP file (download and disk) | roughly 200 KB to 1 MB for a lossy photo (estimate) | image content and quality setting |
| Decoded bitmap in RAM | about 16 MB | pixel dimensions only |

```
2000 x 2000 x 4 bytes = 16,000,000 bytes (about 16 MB)
```

- The 4 bytes per pixel are the red, green, blue, and alpha channels (8 bits each).
- The decoded size is the same whether the file was WebP, PNG, JPEG, or AVIF.
- A 500 KB WebP becomes a 16 MB bitmap, about 32 times larger than the file. Compression only saves network and disk, not RAM.
- If the view only needs 300x300 px, serve a 300x300 image instead: a few KB on the wire and about 0.36 MB decoded.

## 3. WebP can be lossy or lossless

WebP supports both modes. Which one is used depends on the encoder settings.

| Mode | Best for | Notes |
|---|---|---|
| Lossy | Photos, thumbnails, avatars | Smallest files; quality set by encoder (e.g. 75-85) |
| Lossless | Logos, icons, flat graphics | Exact pixels; usually smaller than PNG |

Both modes can support transparency.
