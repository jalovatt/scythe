<section class="segment">

###  <a name="Menu.parseString">Menu.parseString(str)</a>

Finds the positions of any separators (empty items or folders) in a menu string

| **Required** | []() | []() |
| --- | --- | --- |
| str | string | A menu string, of the same form expected by `gfx.showmenu()` |

| **Returns** | []() |
| --- | --- |
| array | A list of separator positions |

</section>
<section class="segment">

###  <a name="Menu.parseTable">Menu.parseTable(menuArr[, captionKey])</a>

Parses a table of menu items into a string for use with `gfx.showmenu()`
```lua
local options = {
  {theCaption = "a", value = 11},
  ...
}


local parsed, separators = Menu.parseTable(options, "theCaption")
```

| **Required** | []() | []() |
| --- | --- | --- |
| menuArr | array | A list of menu items, with separators and folders specified in the same way as expected by `gfx.showmenu()` |

| **Optional** | []() | []() |
| --- | --- | --- |
| captionKey | string | For use with menu items that are objects themselves. If provided, the value of `item[captionKey]` will be used as a caption in the resultant menu string. |

| **Returns** | []() |
| --- | --- |
| string | A menu string |
| array | A list of separator positions (i.e. empty items or folders) |

</section>
<section class="segment">

###  <a name="Menu.getTrueIndex">Menu.getTrueIndex(menuStr, val, separators)</a>

Finds the item that was selected in a menu; `gfx.showmenu()` doesn't account
for folders and separators in the value it returns.

| **Required** | []() | []() |
| --- | --- | --- |
| menuStr | string | A menu string, formatted for use with `gfx.showmenu()` |
| val | The | value returned by `gfx.showmenu()` |
| separators | array | An array of separator positions (empty items and folders), as returned by `Menu.parseString` or `Menu.parseTable` |

| **Returns** | []() |
| --- | --- |
| number | The correct value |
| item | The correct item in `menuStr` |

</section>
<section class="segment">

###  <a name="Menu.showMenu">Menu.showMenu(menu[, captionKey, valKey])</a>

A wrapper to improve the user-friendliness of `gfx.showmenu()`, allowing
tables as an alternative to strings and accounting for any separators or folders
in the returned value. (`gfx.showmenu()` doesn't do this on its own)


Usage:
```lua
local options = {
  {caption = "a", value = 11},
  {caption = ">b"},
  {caption = "c", value = 13},
  {caption = "<d", value = 14},
  {caption = ""},
  {caption = "e", value = 15},
  {caption = "f", value = 16},
}


local index, value = Menu.showMenu(options, "caption", "value")
```
For strings:


```lua
local str = "1|2||3|4|5||6.12435213613"
local index, value = Menu.showMenu(str)


-- User clicks 1 --> 1, 1
-- User clicks 3 --> 4, 3
-- User clicks 6.12... --> 8, 6.12435213613
```

| **Required** | []() | []() |
| --- | --- | --- |
| menu | string&#124;array | A list of menu items, formatted either as a string for `gfx.showmenu()` or an array of items. |

| **Optional** | []() | []() |
| --- | --- | --- |
| captionKey | string | If an array passed for `menu` contains objects rather than simple strings, this parameter should be used to specify which key in the object to use as a caption for the menu item. |
| valKey | string | If an array passed for `menu` contains objects rather than simple strings, this parameter should be used to specify which key in the object to use as the value returned by `Menu.showMenu`. |

| **Returns** | []() |
| --- | --- |
| number | The value, or array index, of the selected item; as with `gfx.showmenu()`, will return `0` if no item is selected |
| any | The caption, or array item, that was selected. If no item was selected, will return `nil` |

</section>