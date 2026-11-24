# Flutter image caching: from the foundations

## 1. An image file and a bitmap are different things

A downloaded JPEG, PNG, or WebP contains **encoded image data**. The file format stores the picture efficiently, often using compression.

To display it, Flutter needs a **decoded image**, also called a bitmap: a grid of pixels that the renderer can use.

```text
JPEG / PNG / WebP bytes
          ↓ decode
Bitmap: a grid of pixels
          ↓ render
Picture on the screen
```

The downloaded file size and the decoded bitmap's memory usage are different. A small compressed file can expand into a large bitmap. A larger bitmap uses more memory.

## 2. Logical pixels and physical pixels

Flutter normally measures widget layouts in **logical pixels**. A screen has **physical pixels**. The device pixel ratio (DPR) connects them:

```text
Physical screen pixels = logical pixels × DPR
```

A 10 × 10 logical-pixel widget on a DPR 3 screen occupies 30 × 30 physical pixels.

**Mapping decoded image pixels to physical screen pixels:** decoded bitmap dimensions are measured in image pixels. To choose a decode size, compare those dimensions directly with the physical screen pixels the widget occupies; do not multiply the decoded dimensions by DPR again. They describe separate pixel grids: the bitmap stores image pixels, while the screen displays physical pixels.

For the 10 × 10 logical-pixel widget at DPR 3:

| Context | Dimensions |
| --- | --- |
| Widget layout | 10 × 10 logical pixels |
| Area on screen | 30 × 30 physical pixels |
| Decoded bitmap for a one-to-one mapping | 30 × 30 image pixels |

In this example, when the whole bitmap fills that area without cropping or additional transforms, each decoded image pixel maps to one physical screen pixel. A 100 × 100 decoded bitmap can also fill the same area; Flutter scales it down while drawing.

A bitmap has its own pixel dimensions. Flutter can draw that bitmap into a larger or smaller area on the screen. Its decoded dimensions do not have to match the display dimensions.

## 3. Decode, cache, and render are three separate jobs

| Job | What it does |
| --- | --- |
| Decode | Converts encoded bytes into a bitmap, using the requested decode size where supported. |
| Cache | Keeps the decoded result available for reuse. |
| Render | Draws the decoded image into the widget's display area. |

Caching does **not** require a second decode. The cached result is also used for display.

### Typical order for Flutter’s built-in image providers

Flutter first checks its shared `ImageCache` using the image provider's key.

```text
Check ImageCache
    ├─ decoded image found ─────────────────────→ Render
    └─ miss → Obtain encoded bytes → Decode → Render
                                      └──────→ Keep decoded result for reuse
```

On a cache miss, where Flutter obtains the encoded bytes depends on the image provider:

- `Image.network`: fetches them from a URL.
- `Image.memory`: uses the supplied bytes.
- `Image.file`: reads them from a file.
- `Image.asset`: loads them from an asset.

**Does an `Image.network` cache miss download the file again?** Yes (proved): when no matching image stream is available in Flutter’s `ImageCache`, `Image.network` fetches the URL again to obtain the encoded bytes and decode them. This includes a request with a different decode-size key, even if another decoded size of the same URL is cached.

Cache hit condition: Different requested decode sizes generally have different keys.

## 4. What the Image.network parameters control

```dart
Image.network(
  squareThumbnailUrl,
  width: 100,
  height: 100,
  cacheWidth: 300,
  cacheHeight: 300,
);
```

`width` and `height` set the display size in logical pixels. `cacheWidth` and `cacheHeight` request the decoded image's pixel dimensions. Despite their names, they control the pixels supplied for display as well as the physical pixels Flutter caches.

Flutter scales the decoded image to fit the display area. If the decoded image supplies too few pixels for that area's physical screen pixels, the displayed image can look blurry. For example, a 100 × 100 logical-pixel image on a device with a pixel ratio of 3 occupies 300 × 300 physical screen pixels, so requesting a 300 × 300 decode can provide enough pixels. The actual decoded size can be smaller if the source image is smaller.

### What happens without cacheWidth and cacheHeight?

**Without `cacheWidth` and `cacheHeight`, Flutter normally decodes the image at its original pixel dimensions.**

Setting a small widget `width` and `height` does not automatically request a smaller decode.

For example, suppose a WebP is **2000 × 2000 pixels**, the widget is **100 × 100 logical pixels**, and DPR is **3**:

| Decode settings | Decoded bitmap dimensions | Physical display dimensions | Approximate bitmap pixel memory |
| --- | --- | --- | --- |
| Both omitted | 2000 × 2000 | 300 × 300 | 15.26 MiB |
| Both set to `300` | 300 × 300 | 300 × 300 | 0.34 MiB |

### Omitting decode dimensions

Omitting `cacheWidth` and `cacheHeight` does not disable memory caching.

## 7. Choosing a useful decode size

For a square thumbnail that fills a square widget:

```text
Target decode size = widget's logical size × DPR
```

```dart
final targetPixels =
    (120 * MediaQuery.devicePixelRatioOf(context)).ceil();

Image.network(
  squareThumbnailUrl,
  width: 120,
  height: 120,
  cacheWidth: targetPixels,
  cacheHeight: targetPixels,
  fit: BoxFit.cover,
);
```

On a DPR 3 screen, this requests a 360 × 360 decode for a 120 × 120 logical-pixel widget.

- Too few decoded pixels can make the displayed image blurry.
- Extra decoded pixels use more memory and may add decoding work.
- If the image will be enlarged or zoomed, choose enough resolution for that larger display size.

For rectangular source images, preserve the source aspect ratio and account for how `fit` scales or crops the image. Setting both decode dimensions to a square is appropriate for the square sources used in these examples.
