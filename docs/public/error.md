# Error
```lua
local Error = require(public.error)
```


<section class="segment">

### Error.handleError([errObject]) :id=error-handleerror

Handles script errors, adding details such as a stack trace and Reaper/library
versions to the Lua error message. Any code called from within the Scythe GUI
loop is automatically wrapped with this, so the typical use-case would be
functions that are run prior to initializing the GUI, or after it closes.


Usage:
```lua
xpcall(myFunction, Error.handleError)
```

</section>

----
_This file was automatically generated by Scythe's Doc Parser._
