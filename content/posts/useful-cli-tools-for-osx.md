+++
title = "Useful CLI tools for OSX"
date = "2019-05-11T14:44:55+01:00"
+++

Over years doing my daily Go programming job, I collected few CLI tools that I use everyday
to improve my terminal experience. Here is the list of those I use the most:

tig
--------------

* `brew install tig`

Everyone dealing with git know browsing the Git repository history using `git log` command.
While this always get optimal results, in some cases I would like to search in the logs or
use different log format. While this is possible via endless combination of `git log` arguments,
the `tig` command provide really nice ncurses interface to accomplish this job.

![tig log][/cli_tig_log.png]

But it is not only the repository history browser. In fact it is much more. I learned to use
`tig status` command to properly split my changes to multiple commits. This command allows you
to manually pick blocks or single lines of changes and make logical commits out from them.

![tig status][/cli_tig_status.png]

lnav
--------------

* `brew install lnav`

I found this gem recently as I'm often dealing with huge sets of Kubernetes control plane logs
that I need to search/filter/etc. Normally, I would use `grep` and pipe the result to `less`.
However, the result might still look disturbing and I always missed colors for things like errors
or warnings. Also word wrapping in `less` is always cumbersome. 

The `lnav` tool provide many ways to filter the log files, but also regular files and it defacto
became an alias for `less` to me.

![lnav][/cli_lnav.png]

bat
-------------

Don't worry, this has nothing to do with flighting creatures. I believe the word `bat` stands for
'better cat'. And it is indeed better in many ways. It adds syntax highlighting to code and line numbers.
It also display changed lines (git), so it turns the `cat foo.go` into full editor display mode.

![bat][/cli_bat.png]