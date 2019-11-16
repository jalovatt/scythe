<section class="segment">

###  <a name="GFX.roundRect">GFX.roundRect(x, y, w, h, r[, antialias, fill])</a>

A wrapper for Reaper's roundrect() function with fill, adapted from mwe's EEL
example.

| **Required** | []() | []() |
| --- | --- | --- |
| x | number |  |
| y | number |  |
| w | number |  |
| h | number |  |
| r | number | Corner radius |

| **Optional** | []() | []() |
| --- | --- | --- |
| antialias | boolean | Defaults to `true` |
| fill | boolean | Defaults to `false` |

</section>
<section class="segment">

###  <a name="GFX.triangle">GFX.triangle(fill, ...)</a>

A wrapper for Reaper's triangle() function with the option to not fill the shape.

| **Required** | []() | []() |
| --- | --- | --- |
| fill | boolean |  |
| ... | number | A series of X and Y values defining the vertices of the shape. |

</section>