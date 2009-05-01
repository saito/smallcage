
SmallCage - Lightweigt CMS Package.


INSTALL

$ sudo gem install smallcage


USAGE

$ smc help

Usage: smc <subcommand> [options]
SmallCage 0.1.3 - Lightweight CMS Package.
Subcommands are:
    update [path]                    Build smc contents.
    clean  [path]                    Remove files generated from *.smc source.
    server [path] [port]             Start HTTP server.
    auto   [path] [port]             Start auto update daemon.
    import [name|uri]                Import project.
    export [path] [outputpath]       Export project.
    manifest [path]                  Generate Manifest.html file.

Options are:

    -h, --help                       Show this help message.
    -v, --version                    Show version info.

$ mkdir htdocs
$ cd htdocs
$ smc import
Import: base
Create:
  /_smc
  /_smc/helpers
  /_smc/helpers/base_helper.rb
  /_smc/helpers/site_helper.rb
  /_smc/templates
  /_smc/templates/default.rhtml
  /_smc/templates/footer.rhtml
  /_smc/templates/header.rhtml

Import these files?[yN]: y
A /_smc
A /_smc/helpers
A /_smc/helpers/base_helper.rb
:

$ smc update
A /index.html
A /sample/index.html
A /sample/redirect.html
A /sample/sub/contents.html
A /sample/sub/index.html

$ smc server . 8080
:
...and access
http://localhost:8080/

