# Math
```lua
local Math = require(public.math)
```


<section class="segment">

### Math.round(n[, places]) :id=math-round

Rounds a number to a given number of places

| **Required** | []() | []() |
| --- | --- | --- |
| n | number |  |

| **Optional** | []() | []() |
| --- | --- | --- |
| places | number | Decimal places. Defaults to 0. |

| **Returns** | []() |
| --- | --- |
| number |  |

</section>
<section class="segment">

### Math.nearestMultiple(n, snap) :id=math-nearestmultiple

Rounds a number to the nearest multiple of a given value

| **Required** | []() | []() |
| --- | --- | --- |
| n | number |  |
| snap | number | Base value for multiples |

| **Returns** | []() |
| --- | --- |
| number |  |

</section>
<section class="segment">

### Math.clamp(a, b, c) :id=math-clamp

Clamps a number to a given range. The returned value is also the median of
the three values. The order of values given doesn't matter.

| **Required** | []() | []() |
| --- | --- | --- |
| a | number |  |
| b | number |  |
| c | number |  |

| **Returns** | []() |
| --- | --- |
| number |  |

</section>
<section class="segment">

### Math.ordinal(n) :id=math-ordinal

Converts a number to an ordinal string (i.e. `30` to `30th`)

| **Required** | []() | []() |
| --- | --- | --- |
| n | number |  |

| **Returns** | []() |
| --- | --- |
| string |  |

</section>
<section class="segment">

### Math.polarToCart(angle, radius[, ox, oy]) :id=math-polartocart

Converts an angle and radius to Cartesian coordinates

| **Required** | []() | []() |
| --- | --- | --- |
| angle | number | Angle in radians, omitting Pi. (i.e. for Pi/4, pass `0.25`) |
| radius | number |  |

| **Optional** | []() | []() |
| --- | --- | --- |
| ox | number | X value of the origin point; returned coordinates will be shifted by this amount. Defaults to 0. |
| oy | number | Y value of the origin point; returned coordinates will be shifted by this amount. Defaults to 0. |

| **Returns** | []() |
| --- | --- |
| number | X value |
| number | Y value |

</section>
<section class="segment">

### Math.cartToPolar(x, y[, ox, oy]) :id=math-carttopolar

Converts Cartesian coordinates to an angle and radius.

| **Required** | []() | []() |
| --- | --- | --- |
| x | number |  |
| y | number |  |

| **Optional** | []() | []() |
| --- | --- | --- |
| ox | number | X value of the origin point; The original coordinates will be shifted by this amount prior to conversion. Defaults to 0. |
| oy | number | Y value of the origin point; The original coordinates will be shifted by this amount prior to conversion. Defaults to 0. |

| **Returns** | []() |
| --- | --- |
| angle | number Angle in radians, omitting Pi. (i.e. for Pi/4, returns `0.25`) |
| radius | number |

</section>

----
_This file was automatically generated by Scythe's Doc Parser._
