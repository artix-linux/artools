artools
=============

User manual

### 1. artools.conf

artools.conf is the central configuration file for artools.
By default, the config is installed in

~~~
/etc/artools/artools.conf
~~~

A user artools.conf can be placed in

~~~
$HOME/.config/artools/artools.conf
~~~

If the userconfig is present, artools will load the userconfig values, however, if variables have been set in the systemwide

~~~
/etc/artools/artools.conf
~~~

these values take precedence over the userconfig.
Best practise is to leave systemwide file untouched.
By default it is commented and shows just initialization values done in code.

Tools configuration is done in artools.conf or by args.
Specifying args will override artools.conf settings.

~~~
$HOME/.config/artools/import.list.d
~~~

overriding

~~~
/etc/artools/import.list.d
~~~
