<section class="segment">

###  <a name="Math.round">Math.round(n[, places])</a>

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

###  <a name="Math.nearestMultiple">Math.nearestMultiple(n, snap)</a>

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

###  <a name="Math.clamp">Math.clamp(a, b, c)</a>

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

###  <a name="Math.ordinal">Math.ordinal(n)</a>

Converts a number to an ordinal string (i.e. `30` to `30th`)

| **Required** | []() | []() |
| --- | --- | --- |
| n | number |  |

| **Returns** | []() |
| --- | --- |
| string |  |

</section>
<section class="segment">

###  <a name="Math.polarToCart">Math.polarToCart(angle, radius[, ox, oy])</a>

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

###  <a name="Math.cartToPolar">Math.cartToPolar(x, y[, ox, oy])</a>

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