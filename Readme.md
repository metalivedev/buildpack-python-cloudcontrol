Python buildpack for dotCloud Apps
==================================

This is a [buildpack](https://www.cloudcontrol.com/dev-center/Platform%20Documentation#buildpacks-and-the-procfile) for Python apps which are being ported from the dotCloud platform. Like the standard `python` buildpack, this powered by [pip](http://www.pip-installer.org/). It also adds `nginx` and `uwsgi`, similar to what the dotCloud Python service provided.

Usage
-----

This the `dotcloud` branch of our default buildpack for Python applications. This is a quick introduction of usage and for more details you should see the [cloudControl documentation for porting dotCloud applications](https://github.com/cloudControl/documentation/tree/dotCloud_migration_guides/Guides/dotCloud-cloudControl%20migration) **TODO: LINK NEEDS UPDATE WHEN FINAL**.

In case you want to introduce some changes, fork our buildpack, apply changes and test it via [custom buildpack feature](https://www.cloudcontrol.com/dev-center/Guides/Third-Party%20Buildpacks/Third-Party%20Buildpacks):

**TODO: Update buildpack URL when merged with cloudControl**

~~~bash
$ cctrlapp APP_NAME create custom --buildpack https://github.com/metalivedev/buildpack-python-cloudcontrol#dotcloud
~~~

The buildpack will use Pip to install your dependencies, vendoring a copy of the Python runtime into your web container.

Choose your Python version
--------------------------

You can also specify arbitrary Python release with a `runtime.txt` file in the application repository root, otherwise `python-2.7.3` will be choosen as a default one:

~~~bash
$ cat runtime.txt
python-3.3.2
~~~

List of supported versions:

* python-2.7.2
* python-2.7.3
* python-2.7.4
* python-2.7.5
* python-3.1.1
* python-3.1.2
* python-3.1.3
* python-3.1.4
* python-3.1.5
* python-3.2.0
* python-3.2.1
* python-3.2.2
* python-3.2.3
* python-3.2.4
* python-3.2.5
* python-3.3.0
* python-3.3.1
* python-3.3.2

# dotCloud Features

Once this buildpack knows which version of Python you want to run, it
will install some dotCloud-related requirements from
`config/dcrequirements.txt` using `pip`. Your own `requirements.txt`
will get installed later and they can update the dotCloud
requirements, but by default these are close to the same versions
configured on the dotCloud platform. A standard cloudControl Python
application would stop its build there and then run according to your
`Profile`. This `dotcloud` branch provides additional features to
better emulate the dotCloud environment.

## Default Behavior

Unless you provide one of your own, the default `Procfile` is:

```
web: $HOME/bin/dcapproot.sh; supervisord -c config/supervisord.conf
```

The default behavior of this buildpack is to install `supervisord`,
`nginx`, and `uwsgi`, then to start `supervisord` with the
configuration file in `config/supervisord.conf`. This in turn will
start nginx and uwsgi as well as your application, as long as you've
named your application `wsgi.py` (the dotCloud default). The
configuration files for `supervisord`, `nginx`, and `uwsgi` will pull
in user configuration files in the same way dotCloud did, which
implies there needs to be a `current/` directory. `dcapproot.sh` will
emulate the links created by dotCloud, though it cannot create the
`~dotcloud` user, so you will need to update any paths that include
`/home/dotcloud`.

## supervisord

This version of the Python buildpack installs
[`supervisord`](http://supervisord.org/), a process control system
that allows you to start multiple processes within your application
container. This is useful to emulate dotCloud where (in addition to
using `supervisord`) the environment ran `nginx` and `uwsgi` for
Python applications.

Error reporting in `supervisord` usually goes out to logs, so we've
added `supervisor-stdout` to the `dcrequirements.txt` to stream the
logs out to standard out so that errors are visible in cloudControl
logs. This Python package must be started and then other processes
must explicitly send it events. Please see `config/supervisord.conf`
for an example of starting `nginx` and `uwsgi` with the correct
logging configuration.

**TODO**: add standard include path for user-configs as was done in
the dotCloud supervisord.conf:

```
[include]
files = /home/dotcloud/current/supervisord.conf
```

**Workaround** Until that TODO is fixed, you'll need to start
  `supervisord` with your own custom `supervisord.conf`.

## Nginx

### `bin/nginx` and `bin/nginx_build`

This branch contains a binary version of Nginx (`/bin/nginx`),
compiled on the cloudControl platform so that it will run well
there. By default `bin/nginx` will be copied over to your application
`bin/`. The version provided by default is `NGINX_VERSION=1.2.9` (as
defined in `bin/nginx_build`). This is the closest version of Nginx to
what was on the dotCloud platform (1.2.1), but there could be many
reasons to update the version (or to update this buildpack to provide
several pre-compiled binaries). So, if you do want to build different
versions of `nginx`, you'll need to do these things:

1. fork this buildpack repository
2. pull a local copy of this buildpack repository. It also works as a
   cloudControl app.
3. create a branch, e.g. "nginxbuilder"
4. edit `bin/nginx_build` to change `NGINX_VERSION`
5. add a `Procfile` containing: `web: bin/nginx_build` and create an
   empty `requirements.txt` as well to make the installer happy.
6. commit your changes
7. create a new cloudControl application using **the standard python
   service**, e.g. `cctrlapp create mybuilder python`
8. push and deploy this application to cloudControl. This compiles
   `nginx` and provide a server to download the binary.,
   e.g. `cctrlapp push mybuilder/nginxbuilder`
9. You'll find the compiled binary in the `sbin` directory,
   e.g. http://nginxbuilder-mybuilder.cloudcontrolled.com/nginx/sbin/
10. Switch back to the `dotcloud` branch.
11. Right-click to download that binary. Copy it to `bin/`. You can
    replace the existing `nginx` or choose a new name (but then you'll
    need to update `bin/compile` to do something smart to pick which
    nginx you want in the app.
12. Commit your changes to `bin/`.
13. Push your changes (now back on your forked repo on the dotcloud branch)
14. Now you can use this updated buildpack with the new `nginx`
    version in the usual way: `cctrlapp mydotcloudapp create custom
    --buildpack
    https://github.com/myusername/buildpack-python-cloudcontrol#dotcloud`

### Configuration

`bin/nginx_start` pre-processes the `config/nginx.conf.template` file
to insert important environment variables, including which ${PORT} to
bind to and the ${HOME} directory for the root of the document tree
(assumes presence of `current/` as created by `dcapproot.sh`). The
template file and resulting `nginx.conf` file emulate the
configuration found on dotCloud Nginx installations, including the
automatic inclusion of application configurations from
`${HOME}/current/*nginx.conf` and uwsgi configurations from
`${HOME}/current/*uwsgi.conf`. Default uWSGI configuration comes from
`config/uwsgi.conf` and gets included in the Nginx configuration.

## uWSGI

dotCloud used [`uWSGI`](https://github.com/unbit/uwsgi) to run Python
web applications. This gets started as a separate process, but Nginx
proxies to it through a `unix` socket created in the ${TMPDIR}. 

The combination of Nginx and uWSGI can give very good performance for
both static content (via Nginx) and dynamically-generated content (via
uWSGI). This buildpack starts supervisord which then starts Nginx and
uWSGI.

uWSGI is *extremely* configurable. You can configure it via Nginx
parameters in `${HOME}/current/*uwsgi.conf`, through environment
variables, and through commandline options. There are some default
commandline options used in `bin/uwsgi_start`.

