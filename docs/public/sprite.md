# Sprite
```lua
local Sprite = require(public.sprite)
```
_Under construction; some functionality may be missing or broken_


The Sprite class simplifies a number of common image use-cases, such as
working with sprite sheets (image files with multiple frames). (Only horizontal
sheets are currently supported)
<section class="segment">

### Sprite:setImage(val) :id=sprite-setimage

Sets the sprite's image via filename or a graphics buffer

| **Required** | []() | []() |
| --- | --- | --- |
| val | string&#124;number | If a string is passed, it will be used as a file path from which to load the image. If a number is passed, the sprite will use that graphics buffer and set its path to the image assigned there. |

</section>
<section class="segment">

### Sprite:draw(x, y[, frame]) :id=sprite-draw

Draws the sprite

| **Required** | []() | []() |
| --- | --- | --- |
| x | number |  |
| y | number |  |

| **Optional** | []() | []() |
| --- | --- | --- |
| frame | number | In conjunction with the sprite's frame.w and frame.h values, determines the source area to draw. Frames are counted from left to right, starting at 0. |

</section>