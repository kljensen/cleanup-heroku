# Cleanup Heroku

**Table Of Contents**
- [Project description](#project-description)
- [Installation](#installation)
- [Example Usage](#example-usage)
- [Contributing](#contributing)
- [Change log](#change-log)
- [License](#license)

#### Project description:
I ❤️ [Heroku](https://www.heroku.com): it is a fantastic place to deploy web applications and 
I use it all the time. Alas, because of my heavy use, and particularly my use of Heroku in 
my teaching, I tend to accumulate a bunch of unused applications. The purposes of this script
are 1) to help me identify my Heroku apps that are old or disused; and, 2) to delete those
apps.

☠☢⚠️ **CAUTION** ☠☢⚠️  — you can *easily* destroy your production Heroku apps with this shell
script. Consider yourself warned — be careful!

## Installation

You can either install this project by checking out the git repo

```
git clone https://github.com/kljensen/cleanup-heroku.git
```

Or by downloading the `cleanup-heroku.sh` shell script directly

```
curl -O https://raw.githubusercontent.com/kljensen/cleanup-heroku/main/cleanup-heroku.sh
```

**Requirements/Dependencies:**
- The [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)
- A Posix-compliant shell (`/bin/sh`: [the Bourne shell](https://en.wikipedia.org/wiki/Bourne_shell) by default)
- Posix-compliant implementations of `sed` and `grep`


## Example Usage

The shell script has two commands: `list` and `destroy`. The `list` command produces pipe-delimited
output showing the following detail about each of your apps: the app name, the app's buildpack (language),
the app's release date (when you last deployed), the date of the latest logs for the app, and
the app's URL. If an app hasn't been active in a log time, the logs can be empty and in that
case the date of the latest log is `null`. Also, the last log date is not necessarily the
last date at which the app received traffic; sometimes your app is restarted by Heroku
and The output looks like the following:

```
>  ./cleanup-heroku.sh list -c 
app|buildpack|release_date|last_log_date|web_url
ancient-peak-87842|null|2019-11-15|null|https://ancient-peak-87842.herokuapp.com/
cspc213-kljensen-server-hw|Node.js|2018-01-26|null|https://cspc213-kljensen-server-hw.herokuapp.com/
desolate-lowlands-61544|Go|2020-09-24|null|https://desolate-lowlands-61544.herokuapp.com/
evening-escarpment-72443|Go|2019-10-01|null|https://evening-escarpment-72443.herokuapp.com/
eventbrite-demo-app|Node.js|2018-11-29|2020-11-29|https://eventbrite-demo-app.herokuapp.com/
exam1-solution-2018|Node.js|2018-02-22|2020-11-25|https://exam1-solution-2018.herokuapp.com/
fast-fortress-4992-561|null|2013-09-13|null|https://fast-fortress-4992-561.herokuapp.com/
fast-retreat-88859|Go|2020-11-10|null|https://fast-retreat-88859.herokuapp.com/
floating-island-51786|Node.js|2017-10-30|null|https://floating-island-51786.herokuapp.com/
```

If you omit the `-c` flag, the first row is omitted. You can optionally provide
a list of applications as follows:

```
> ./cleanup-heroku.sh list -c ancient-peak-87842 eventbrite-demo-app 
app|buildpack|release_date|last_log_date|web_url
ancient-peak-87842|null|2019-11-15|null|https://ancient-peak-87842.herokuapp.com/
eventbrite-demo-app|Node.js|2018-11-29|2020-11-29|https://eventbrite-demo-app.herokuapp.com/
```

If you want the output to look prettier, you can use something like 
[xsv](https://github.com/BurntSushi/xsv) or [csvkit](https://github.com/wireservice/csvkit).
For example, the following command shows a nice table

```
> ./cleanup-heroku.sh list -c  |xsv table -d '|'
app                         buildpack  release_date  last_log_date  web_url
ancient-peak-87842          null       2019-11-15    null           https://ancient-peak-87842.herokuapp.com/
cspc213-kljensen-server-hw  Node.js    2018-01-26    null           https://cspc213-kljensen-server-hw.herokuapp.com/
desolate-lowlands-61544     Go         2020-09-24    null           https://desolate-lowlands-61544.herokuapp.com/
evening-escarpment-72443    Go         2019-10-01    null           https://evening-escarpment-72443.herokuapp.com/
eventbrite-demo-app         Node.js    2018-11-29    2020-11-29     https://eventbrite-demo-app.herokuapp.com/
exam1-solution-2018         Node.js    2018-02-22    2020-11-25     https://exam1-solution-2018.herokuapp.com/
fast-fortress-4992-561      null       2013-09-13    null           https://fast-fortress-4992-561.herokuapp.com/
fast-retreat-88859          Go         2020-11-10    null           https://fast-retreat-88859.herokuapp.com/
floating-island-51786       Node.js    2017-10-30    null           https://floating-island-51786.herokuapp.com/
```

The `list` command takes a while because it calls the `heroku` command for
each app and therefore is making Heroku API requests under the hood. As
such, you likely want to pipe the output of the `list` command to a temporary
file, e.g. `./cleanup-heroku.sh list -c >my-apps.txt`.

The `destroy` command is a thin wrapper around the `destroy` command
of the `heroku` command. You can destroy apps by name something like as follows:

```
> ./cleanup-heroku.sh destroy floating-island-51786  fast-retreat-88859 
```

As such, you'll need to type each app's name to confirm that you want to
delete the app. If you're _certain_ you want to destroy the apps, you 
can use the `-y` flag to skip this confirmation. You should use that
with caution ⚠️⚠️⚠️!

If you want a _one-shot_ interactive command by which you can list, select, and
destroy your apps, consider using [fzf](https://github.com/junegunn/fzf) as follows:

```
./cleanup-heroku.sh list -c | xsv table -d'|' | fzf -m | cut -f1 -d' ' |xargs -o ./cleanup-heroku.sh destroy
```

Or, if you are brave, you can add the `-y` to `destroy` in order to destroy apps without
needing to confirm by typing their names

```
./cleanup-heroku.sh list -c | xsv table -d'|' | fzf -m | cut -f1 -d' ' |xargs -o ./cleanup-heroku.sh destroy -y
```

Of course, because of the slowness of the `list` command, you may wish
to use a temporary file instead of a pipe, as described above.

```
./cleanup-heroku.sh list -c >my-apps.txt
cat my-apps.txt | xsv table -d'|' | fzf -m | cut -f1 -d' ' |xargs -o ./cleanup-heroku.sh destroy 
```

Of course, the `xsv` is only a nicety above.

## Contributing

All issues and pull requests are welcome. I ask only that you run
[ShellCheck](https://github.com/koalaman/shellcheck) before submitting a pull
request.

## Change Log
[CHANGELOG.md](./CHANGELOG.md)

## License (the Unlicense)

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
