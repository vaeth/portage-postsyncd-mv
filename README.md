# portage-postsyncd-mv

postsync hooks for portage to sync from git

(C) Martin Väth (martin at mvath.de).

This project is under the GPL-2 license

This project provides several files which can be used for syncing with
portage via git or github.

The problem when syncing via git is that several files like the metadata cache,
the news announcements, the GLSAs, dtd, xml-schema, and project.xml files
are not modified and must be updated/fetched independently.

This project is loosely inspired by
-	https://github.com/hasufell/portage-gentoo-git-config

but it aims to be much more flexible and configurable.

Moreover, it aims to be more secure, since root permissions are dropped
as soon as possible.

These scripts will work no matter whether you use git syncing or not:
When you do not sync from git, a lot of tasks will be skipped, automatically.


## Installation

Emerge the `app-portage/portage-postsyncd-mv` ebuild from the mv overlay.
Alternatively, copy the content of `repo.postsync.d/` to
`/etc/portage/repo.postsync.d/`, the content of `bin/` to your `$PATH`
(perhaps `/usr/bin`). For __zsh completion__ support, copy the content of
`zsh/` to your zsh's `$fpath` (perhaps `/usr/share/zsh/site-functions`).
To get the hack for `q-reinit` mentioned below, also copy the file
`app-portage/portage-utils` into `/etc/portage/env/app-portage/`
(creating this directory and its parents if it does not exist yet).

## Configuration

There are sane defaults, but if you need a nonstandard setting,
you can configure a lot of details through `POSTSYNC_*` variables
in your `/etc/portage/make.conf`. Read `repo.postsync.d/README`
for the available variables and their default values.

If you use `<=app-portage/portage-utils-0.74-r1`, it is recommended to call
```
chmod a-x /etc/portage/repo.postsync.d/q-reinit
```

(The file `app-portage/portage-utils` - when copied to
`/etc/portage/env/app-portage/` - is a hack which will make this
happen automatically at any future emerge of `app-portage/portage-utils`).
In this way, the script `/etc/portage/repo.postsync.d/q-reinit`
will be executed at a more appropriate time of syncing and with more
explicit output by `/etc/portage/repo.postsync.d/??-q-reinit`.
However, the latter script is careful to not do anything if you have
not executed the above command - so nothing really bad will happen
if you do not follow the above recommendation.

Of course, it is also possible to remove the executable bits of some
files of this project in `/etc/portage/repo.postsync.d/*`.
Then, of course, the corresponding functionality will be switched off.
The project is written in such a way that this is not harmful.

Except for setting permissions of your repositories and
calling egencache for your non-main repositories
(and `q-reinit` for all repositories), the scripts do nothing
unless you configure your main repository to be fetched via git.
The scripts recognize the latter by checking that the sync-uri
of your `$POSTSYNC_MAIN_REPOSITORY` ends with `.git`.

This project does intentionally not include some configuration file
to force the latter, because it is up to the user whether he wants this.
If you want it, you must set up `/etc/portage/repos.conf` correspondingly.
For instance, you might have files with the content

`/etc/portage/repos.conf/00-defaults.conf`:
```
[DEFAULT]
main-repo = gentoo
```
`/etc/portage/repos.conf/50-defaults.conf`:
```
[gentoo]
location = /usr/portage
priority = 5000
auto-sync = yes
sync-type = git
sync-depth = 0
sync-uri = https://github.com/gentoo/gentoo.git
```
In this example,
- `location` is the path to the main (gentoo) repository
- `priority` determines the order of the main repository relative to the others
- `auto-sync` means that `emerge --sync` will actually sync it
- `sync-type` means that git will be used for syncing
- `sync-depth` determines how long will be the history which you can see
   with git; the value 0 means full history.

Specify `sync-depth = 1` if you are not interested in any `ChangeLogs`:
This will need half of the disk space (or even less in some future).

However, the scripts in this project will also regularly recompress your
git history (with git repack) so that it needs less disk space.
The latter takes some time, of course. As mentioned above, read
`repo.postsync.d/README` to learn how to configure such details.

These scripts make use of some timestamps.
These are stored locally in the `$location/local/timestamps` directory
(which is created if it does not exist). Here, `$location` is the path to
the (main) repository.
