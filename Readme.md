Python buildpack
================

This is a [buildpack](https://www.cloudcontrol.com/dev-center/Platform%20Documentation#buildpacks-and-the-procfile) for Python apps, powered by [pip](http://www.pip-installer.org/).

Usage
-----

This is our default buildpack for Python applications. In case you want to introduce some changes, fork our buildpack, apply changes and test it via [custom buildpack feature](https://www.cloudcontrol.com/dev-center/Guides/Third-Party%20Buildpacks/Third-Party%20Buildpacks):

~~~bash
$ cctrlapp APP_NAME create custom --buildpack https://github.com/cloudControl/buildpack-python.git
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
