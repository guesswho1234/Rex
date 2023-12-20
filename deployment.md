# how to deploy to heroku
## Heroku 22 Stack
-Distributor ID: Ubuntu
-Description:    Ubuntu 22.04.3 LTS
-Release:        22.04
-Codename:       jammy

## add r buildpack (for running r shiny)
`heroku buildpacks:set -a rexams https://github.com/virtualstaticvoid/heroku-buildpack-r`

### run.R
sets up the shiny app environment

### init.R 
allows to install additional packages with "helpers.installPackages" allowing caching

## add dpkg buildpack (for installing additional packages; put first as buildpack order matters)
`heroku buildpacks:add --index 1 -a rexams https://github.com/rricard/heroku-buildpack-dpkg.git`

## create file named "Debfile" in repository and add the following lines
- http://archive.ubuntu.com/ubuntu/pool/main/p/poppler/libpoppler-cpp0v5_22.02.0-2_amd64.deb
- http://archive.ubuntu.com/ubuntu/pool/main/p/poppler/libpoppler-dev_22.02.0-2_amd64.deb
- http://ports.ubuntu.com/pool/main/p/poppler/libpoppler-cpp-dev_22.02.0-2_arm64.deb

## set heroku environment variables (to find via dpkg installed packages)

`heroku config:set INCLUDE_DIR=/app/.dpkg/usr/include/poppler/cpp/ --app rexams`
`heroku config:add LD_LIBRARY_PATH=/app/.dpkg/usr/lib/x86_64-linux-gnu/:/app/R/lib/R/lib:/app/tcltk/lib --app rexams`	

# some useful commands
## check intalled packages on ubuntu system
apt list --installed
dpkg --list | grep poppler

## connect to project filesystem
C:\Users\User> heroku run bash -a rexams

## check environment variable "PATH"
echo $PATH

## append to environment variable "PATH"
PATH="$PATH:/app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/"

## pkgconfig (found multiple pkgconfig files, need to link all in config var?)
find / -iname pkgconfig

## poppler-cpp.pc
find / -iname *poppler-cpp.pc*

find / -iname *jdk-17-oracle-x64*
/app/.dpkg/usr/lib/jvm/jdk-17-oracle-x64
				

## poppler-cpp.pc contents
cat poppler-cpp.pc

## download file	from bash
curl -F "file=@p<file>" https://file.io

# new method via dpkg and installing poppler via the Debfile
## add dpkg buildpack
heroku buildpacks:add --index 1 -a rexams https://github.com/rricard/heroku-buildpack-dpkg.git

## create a file named "Debfile" (no file extension) and add the following lines:
		http://archive.ubuntu.com/ubuntu/pool/main/p/poppler/libpoppler-cpp0v5_22.02.0-2_amd64.deb
		http://archive.ubuntu.com/ubuntu/pool/main/p/poppler/libpoppler-dev_22.02.0-2_amd64.deb
		http://ports.ubuntu.com/pool/main/p/poppler/libpoppler-cpp-dev_22.02.0-2_arm64.deb

## set heroku environment variables
heroku config:set LIB_DIR=/app/.dpkg/usr/lib/x86_64-linux-gnu/ --app rexams 
heroku config:set INCLUDE_DIR=/app/.dpkg/usr/include/poppler/cpp/ --app rexams
heroku config:add LD_LIBRARY_PATH=/app/.dpkg/usr/lib/x86_64-linux-gnu/:/app/R/lib/R/lib:/app/tcltk/lib --app rexams	
# bash file system info used to derive environment variable values
===============================================================================
/app/.dpkg/usr/lib/x86_64-linux-gnu/
	libpng12.so.0            libpoppler-glib.so        libpoppler.a
	libpoppler-cpp.a         libpoppler-glib.so.8      libpoppler.so
	libpoppler-cpp.so        libpoppler-glib.so.8.4.0  libpoppler.so.27
	libpoppler-cpp.so.0      libpoppler-qt4.a          libpoppler.so.27.0.0
	libpoppler-cpp.so.0.2.0  libpoppler-qt4.so         pkgconfig
	libpoppler-cpp.so.0.9.0  libpoppler-qt4.so.4
	libpoppler-glib.a        libpoppler-qt4.so.4.0.0	

===============================================================================
/app/.dpkg/usr/lib/x86_64-linux-gnu/pkgconfig/
	poppler-cairo.pc  poppler-glib.pc  poppler-splash.pc
	poppler-cpp.pc    poppler-qt4.pc   poppler.pc

what is this? is this needed? what installs this? can we remove something?
/app/.dpkg/usr/lib/aarch64-linux-gnu/pkgconfig/
	poppler-cpp.pc	

===============================================================================

/app/.dpkg/usr/include/poppler/cpp/
	poppler-destination.h    poppler-global.h           poppler-rectangle.h
	poppler-document.h       poppler-image.h            poppler-toc.h
	poppler-embedded-file.h  poppler-page-renderer.h    poppler-version.h
	poppler-font-private.h   poppler-page-transition.h  poppler_cpp_export.h
	poppler-font.h           poppler-page.h
	
=============================================================================
	
/app/.dpkg/usr/lib/x86_64-linux-gnu/
	libpng12.so.0            libpoppler-glib.so        libpoppler.a
	libpoppler-cpp.a         libpoppler-glib.so.8      libpoppler.so
	libpoppler-cpp.so        libpoppler-glib.so.8.4.0  libpoppler.so.27
	libpoppler-cpp.so.0      libpoppler-qt4.a          libpoppler.so.27.0.0
	libpoppler-cpp.so.0.2.0  libpoppler-qt4.so         pkgconfig
	libpoppler-cpp.so.0.9.0  libpoppler-qt4.so.4
	libpoppler-glib.a        libpoppler-qt4.so.4.0.0