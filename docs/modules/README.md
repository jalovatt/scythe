# Modules

Scythe modules should always be imported via `require` rather than `loadfile`, as their functionality may depend on maintaining an internal state. Paths for `require` use dots as separators rather than slashes and must not include file extensions:

```lua
local File = require("public.file")
```

## Public

Modules with the `public` prefix are completely standalone; they each provide specific functionality that can be used in any script. (Scythe should still be loaded first, as some modules also make use of each other).

## GUI

Modules with the `gui` prefix are part of Scythe's GUI, and cannot typically be used on their own. Scripts using the GUI will normally only need the `core` module; it loads the others as needed:

```lua
local GUI = require("gui.core")
```
