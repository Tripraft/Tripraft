# Public web images

Vite serves files in this folder at `/images/` and copies them into the production build. These are public browser assets, so do not place private uploads or credentials here.

This directory contains nine PNG illustrations for the landing-page animation and the `planner-demo/` folder of sample destination photos and portraits.

- [Animation asset mapping](ANIMATION_IMAGES.md) lists the PNG filenames, CSS slots and component responsible for rendering them.
- [Demo photo sources](planner-demo/README.md) records the local demo photos and their source image IDs.
- [Apps file guide](../../../README.md) explains every asset alongside the source files that use it.

Use a public asset from a component with its browser URL:

```jsx
<img src="/images/map.png" alt="Travel map" />
```

If an image should be imported and processed by the bundler, put it under `src/assets/` instead, as with the place-photo fallback SVG. User-uploaded partner media is served by the API and belongs outside this static folder.

When adding an image, use a descriptive filename, resize and compress it for its actual display size, supply suitable alternative text, record its source and usage permission, and update the relevant guide. Verify references when renaming files; public image URLs are literal strings rather than module imports.
