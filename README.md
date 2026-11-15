# Cuto 🍊

A lightweight, touch-first **2D fruit cutting prototype**, built from scratch in a single HTML file.

## Run

Open `index.html` in a modern browser. For an iPhone, host the repository using GitHub Pages (Settings → Pages → Deploy from a branch → main → root), then open the Pages URL in Safari.

## Controls

- Swipe/drag across fruit to cut it.
- Swipe across pieces again to subdivide them.
- **Reset fruit** restores the current fruit.
- **Next fruit** cycles through orange, watermelon, kiwi, lemon, apple, and lime.

## Implementation

The game uses HTML Canvas, pointer events, and convex polygon clipping to split pieces along swipe lines. Textures are generated on a separate canvas and clipped to the polygon pieces. Physics and juice effects are lightweight and designed for mobile browsers.

## Current limitations

This is an initial playable prototype, not a finished production game. Physics uses simple plate contact rather than a full collision solver; cut pieces do not yet collide with one another. Fruit artwork is procedural rather than hand-painted, and complex cuts or very small fragments may be simplified. The game has not yet been tested on a physical iPhone.

## Next steps

Improve collision handling, visual fidelity, cutting accuracy for fast gestures, and test on Safari/iOS.
