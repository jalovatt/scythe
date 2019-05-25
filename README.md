# Scythe (WIP)

This repository is the home of Scythe (formerly Lokasenna_GUI), a graphical framework for Lua scripts in the Reaper digital audio workstation.

Everything here is a work in progress, and **under no circumstances should this be used in scripts intended for public release**. When the time comes, a stable release will be made available via ReaPack.

## Contributing

This is a big project, and I would love some help.

- I've created a long list of features and bugs, and identified a subset that I feel are important to take care of prior to another release. Some are fairly large or complicated tasks, while others are tiny and straightforward - if something catches your eye, let me know and we can go over it in more detail.

- Not all of the features are specific to the GUI - the library has a number of standalone modules that can be used by any script, such as math and table functions, so if the idea of working on the GUI itself seems daunting there's still plenty to do.

- I'd like to use a "feature branch" approach to Git - all work should be done in a separate branch, then submitted as a pull request for approval and merging into _master_.

- In lieu of proper testing (which may come later), the repo includes several example scripts. Use those as a reference to make sure that any changes haven't broken anything. New features may require more examples or modifications to the existing ones. Ideally, nothing should be considered "done" if it isn't being demonstrated in an example.

Cheers!
