# rancid
Home made extensions for Rancid

For now, this covers fetching configuration of Checkpoint's R77.30 Gaia configuration and F5 LTM v15.x configuration

# Gaia R77.30 installation

## ~/bin/glogin
Highly experimental : Just took another *login file and tried to adapt it to gaia structure. Works well enough, but I don’t really understand all of the underlying mechanics, so it may need updating in further Gaia versions (R80 ?)
Script can be found here and should be placed in ~bin directory, with executable rights and rancid:rancid ownership as follows
```
[rancid@rancid ~]$ ls -las ~/bin/glogin
24 -rwxr-xr-x 1 rancid rancid 24276 Jan 23  2018 /home/rancid/bin/glogin
```
## ~/etc/rancid.types.base
In this file, add the Gaia section as show in the source files

## ~/lib/rancid/gaia.pm
The perl module to handle gaia commands should be placed in this location.
You can find this lib in the sources
Give it rancid:rancid ownership as follows : 
```
[rancid@fbo6isp1 ~]$ ls -las ~/lib/rancid/gaia.pm
8 -rw-r--r-- 1 rancid rancid 6267 Jan 23  2018 /home/rancid/lib/rancid/gaia.pm
```

# F5 v15 installation

## Prerequisite configuration on bigip device
We need to create a rancid user with Guest access to all partitions and a tmsh shell.

There are 3  commands we need to pass as rancid user before trying to connect to them via rancid :
```
rancid@(host)(cfg-sync Standalone)(Active)(/Common)(tmos)# mod cli pref pager disabled
rancid@(host)(cfg-sync Standalone)(Active)(/Common)(tmos)# mod cli pref  display-threshold 0
```
These commands are necessary to remove the auto paging.
```
rancid@(host)(cfg-sync Standalone)(Active)(/Common)(tmos)# mod cli pref prompt {user}
```
This command is necessary to custom the prompt and make it look like this :
```
rancid(tmos)# 
```
Too much special characters (parentheses and slashes) don’t mix well with expect, a component of rancid login scripts.

##  ~/bin/f5login
Highly experimental : Just took another *login file and tried to adapt it to tmos structure. Script can be found here and should be placed in ~bin directory, with executable rights and rancid:rancid ownership as follows
```
[rancid@rancid ~]$ ls -las ~/bin/f5login
24 -rwxr-xr-x 1 rancid rancid 24276 Jan 23  2018 /home/rancid/bin/f5login
```
##  ~/etc/rancid.types.base
Modify the rancid.types.base as shown in source files
## ~/lib/rancid/bigip.pm
The perl module to handle bigip commands should be replaced by the one in the sources




