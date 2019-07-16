Watchman Collection
===================
Name pending: Possible option = JewelryBox, other containers also reasonable.

**Clone with**
```bash
git clone --recursive https://github.com/morganaskins/watchmancollection.git
./update.sh
```

This repository is an organized dumping ground for watchman related code which
should include useful tools (such as watchmakers and sibyl), related analysis
scripts, macro files, and anything else that does not belong directly in
rat-pac. Larger tools (again like watchmakers and sibyl) can live within their
own home repositories, but should be linked here as a git submodule.

_Note: This directory is based partially on git submodules, run update.sh to
collect submodule changes. This script will also setup two git hooks to update
submodules on checkout and merge._

Submodules
----------
Example of how to install a submodule, using sibyl as an example
```bash
git submodule add https://github.com/ait-watchman/sibyl.git
```
