# transparent images on chrome

## what's this gray background

### transparent images

On my homepage, I have a map as an avif & png image
with a transparent background.
At some point, I noticed that chrome added an ugly gray background to it,
ruining the point of the transparency...

It's added as an inline style on the html element:

```html
<img
  style="display: block;-webkit-user-select: none;margin: auto;cursor: zoom-in;background-color: hsl(0, 0%, 90%);transition: background-color 300ms;"
  src="..."
/>
```

Since it's an inline style,
it can't be overridden from css.
The easiest way to get back my transparency seems to be
to generate the image element with its own inline styke.
I chose to set the background color explicitly to transparent
(oklab with an alpha channel).

```html
<img style="background-color:oklch(0 0 0/0)" src="..." />
```

Chromium seems to add it here:
https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/core/html/image_document.cc;drc=86fad4c38a31aba9334ad0d3917848510ea502f4;l=427

Which was done in this change
https://chromium-review.googlesource.com/c/chromium/src/+/2455448

for this bug
https://issues.chromium.org/issues/40577140
