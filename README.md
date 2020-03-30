_**This project is on hold for the forseeable future, as I simply don't have enough time to give it the attention it needs. I'm happy to look into any bugs that may show up, however, and pull requests are still more than welcome.**_

# Scythe

This repository is the home of Scythe (formerly Lokasenna_GUI), a graphical framework and utility library for Lua scripts in the [Reaper](https://www.reaper.fm/) digital audio workstation.

Scythe is currently available via [ReaPack](https://reapack.com/), as a pre-release. All of the functionality for v3 is complete; it's just a matter of making sure everything is documented.

## Installation and Usage

See the project's [documentation](https://jalovatt.github.io/scythe).

## Contributing

This is a big project, and I would love some help.

- I've created a long list of features and bugs, and identified a subset that I feel are important to take care of prior to another release. Some are fairly large or complicated tasks, while others are tiny and straightforward - if something catches your eye, let me know and we can go over it in more detail.

- Many features are unrelated to the GUI - the library has a number of standalone modules that can be used by any script, such as math and table functions, so if the idea of working on the GUI itself seems daunting there's still plenty to do.

- All work should be done in a separate feature branch, then submitted as a pull request for approval and merging into `master`.

- Standalone modules can make use of Scythe's test runner. As far as GUI modules are concerned, the repo includes several example scripts - use those as a reference to make sure that any changes haven't broken anything. New features may require more examples or modifications to the existing ones. Ideally, nothing should be considered "done" if it isn't being demonstrated in an example.

## Coding Style

For the most part, I've tried to follow [the Olivine Labs style guide](https://github.com/Olivine-Labs/lua-style-guide), with a few exceptions:

- 2 spaces for indents
- `pascalCase` for names
- Everything should be `local` unless there's a very good reason

I also use [Luacheck](https://github.com/mpeterv/luacheck) to help spot potential bugs or style problems. There are extensions for most popular editors to provide live checking of your code. A `.luacheckrc` file is included with the repo, and I'm certainly open to changing the rules it uses.

## Donations

If you've found Scythe helpful, or my messy code has made you feel better about your own, or you just really like my Github avatar, I'm happy to accept contributions [via PayPal](https://www.paypal.me/Lokasenna).

Cheers!
