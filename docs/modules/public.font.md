<section class="segment">

###  <a name="Font.addFonts">Font.addFonts(fonts)</a>

Adds fonts to the available presets, or overrides existing ones.

| **Required** | []() | []() |
| --- | --- | --- |
| fonts | hash | A table of preset arrays, of the form `{ presetName: { fontName, size, "biu" } }`. |

</section>
<section class="segment">

###  <a name="Font.set">Font.set(fontIn)</a>



| **Required** | []() | []() |
| --- | --- | --- |
| fontIn | string&#124;array | An existing preset (`"monospace"`, `1`) or an array of font parameters: `{ fontName, size, "biu" }`. |

</section>
<section class="segment">

###  <a name="Font.exists">Font.exists(fontName)</a>

Checks if a given font exists on the current system

| **Required** | []() | []() |
| --- | --- | --- |
| fontName | string | The name of a font. |

| **Returns** | []() |
| --- | --- |
| boolean |  |

</section>