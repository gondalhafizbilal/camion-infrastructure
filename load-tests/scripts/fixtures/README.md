# Fixtures

`sample-image.jpg` is **not committed**. Place any small JPEG here (50–200 KB is realistic) before building the runner image:

```sh
# Quick way: grab a placeholder
curl -sSL https://picsum.photos/800/600.jpg -o sample-image.jpg
```

The `image-upload.js` scenario opens this file at k6 init time. The build will fail if it's missing.
