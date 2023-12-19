# Heroku Buildpack
With init.R and run.R in place, we can push directly to Heroku.
However, we need to select a buildpack that tells Heroku how to handle the shiny app.
We use: https://github.com/virtualstaticvoid/heroku-buildpack-r

heroku cli command:
heroku buildpacks:set -a rexams https://github.com/virtualstaticvoid/heroku-buildpack-r

# check intalled packages
why do i need buildpack when packages are already pre-installed

apt list --installed
dpkg --list | grep poppler

# Poppler buildpack
To be able to use the pdftools package we need poppler to be available. 
For this we additionally need to add the following buildpack as well and put it into the first spot such that it is loaded before any other buildpack.
Additionally, we need to set some config vars in order for poppler to be found.

heroku cli commands:
heroku buildpacks:add --index 1 -a rexams https://github.com/amitree/heroku-buildpack-poppler
heroku config:set -a rexams PKG_CONFIG_PATH=/app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig
heroku config:set -a rexams INCLUDE_DIR=/app/.apt/usr/include/poppler/cpp
heroku config:set -a rexams PATH=/app/R/lib/R/bin:/app/tcltk/bin:/app/pandoc/bin:/usr/local/bin:/usr/bin:/bin:/app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig

# error when building with buildpack https://github.com/amitree/heroku-buildpack-poppler
remote:        ** testing if installed package can be loaded from temporary location        
remote:        Error: package or namespace load failed for âpdftoolsâ in dyn.load(file, DLLpath = DLLpath, ...):        
remote:         unable to load shared object '/app/R/site-library/00LOCK-pdftools/00new/pdftools/libs/pdftools.so':        
remote:          /app/R/site-library/00LOCK-pdftools/00new/pdftools/libs/pdftools.so: undefined symbol: _ZNK7poppler8document10create_tocEv        
remote:        Error: loading failed        
remote:        Execution halted        
remote:        ERROR: loading failed        
remote:        * removing â/app/R/site-library/pdftoolsâ        
remote:                
remote:        The downloaded source packages are in        
remote:        	â/tmp/RtmpfxUYya/downloaded_packagesâ        
remote:        Warning message:        
remote:        In install.packages("pdftools", verbose = TRUE) :        
remote:          installation of package âpdftoolsâ had non-zero exit status

This would be an alternative buildpack.

heroku cli commands:
heroku buildpacks:add --index 1 -a rexams https://github.com/k16shikano/heroku-buildpack-poppler
heroku config:set -a rexams PKG_CONFIG_PATH=/app/vendor/poppler/lib/pkgconfig/
heroku config:set -a rexams INCLUDE_DIR=/app/vendor/poppler/include/poppler/cpp/

# error when building with buildpack https://github.com/k16shikano/heroku-buildpack-poppler (SAME ERROR)
remote:        ** testing if installed package can be loaded from temporary location        
remote:        Error: package or namespace load failed for âpdftoolsâ in dyn.load(file, DLLpath = DLLpath, ...):        
remote:         unable to load shared object '/app/R/site-library/00LOCK-pdftools/00new/pdftools/libs/pdftools.so':        
remote:          /app/R/site-library/00LOCK-pdftools/00new/pdftools/libs/pdftools.so: undefined symbol: _ZNK7poppler8document10create_tocEv        
remote:        Error: loading failed        
remote:        Execution halted        
remote:        ERROR: loading failed        
remote:        * removing â/app/R/site-library/pdftoolsâ        
remote:        * restoring previous â/app/R/site-library/pdftoolsâ

# some bash commands used to find out paths etc.
## run bash (connect from powershell)
C:\Users\User> heroku run bash -a rexams

## check and set path (tried to add pkgconfig to path to spare config vars, not sure if this worked or not anymore, using config vars for now)
~/R/site-library $ echo $PATH
	/app/R/lib/R/bin:/app/tcltk/bin:/app/pandoc/bin:/usr/local/bin:/usr/bin:/bin
~/R/site-library $ PATH="$PATH:/app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/"

## pkgconfig (found multiple pkgconfig files, need to link all in config var?)
find / -iname pkgconfig
	./tcltk/lib/pkgconfig
	./R/lib/pkgconfig
	./.apt/usr/lib/x86_64-linux-gnu/pkgconfig

## poppler-cpp.pc (https://github.com/amitree/heroku-buildpack-poppler)
find / -iname poppler-cpp.pc
	/app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/poppler-cpp.pc	
		~ $ cd /app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/
			~/.apt/usr/lib/x86_64-linux-gnu/pkgconfig $ dir
				poppler-cpp.pc  poppler-splash.pc  poppler.pc
				
## poppler-cpp.pc (https://github.com/k16shikano/heroku-buildpack-poppler)
find / -iname poppler-cpp.pc
	/app/vendor/poppler/lib/pkgconfig/poppler-cpp.pc			

## poppler/cpp path (https://github.com/amitree/heroku-buildpack-poppler)
find / -xdev 2>/dev/null -name "poppler"
	~ $ cd ./.apt/usr/include/poppler/cpp
		~/.apt/usr/include/poppler/cpp $ dir
			poppler-destination.h    poppler-font.h    poppler-page-renderer.h    poppler-rectangle.h
			poppler-document.h       poppler-global.h  poppler-page-transition.h  poppler-toc.h
			poppler-embedded-file.h  poppler-image.h   poppler-page.h             poppler-version.h

## poppler/cpp path (https://github.com/k16shikano/heroku-buildpack-poppler)
/app/.apt/usr/include/poppler/cpp
	poppler-destination.h    poppler-font.h    poppler-page-renderer.h    poppler-rectangle.h
			poppler-document.h       poppler-global.h  poppler-page-transition.h  poppler-toc.h
			poppler-embedded-file.h  poppler-image.h   poppler-page.h             poppler-version.h

## poppler-cpp.pc contents
cat poppler-cpp.pc
	prefix=/usr
	libdir=/usr/lib/x86_64-linux-gnu
	includedir=/usr/include

	Name: poppler-cpp
	Description: cpp backend for Poppler PDF rendering library
	Version: 0.81.0
	Requires:
	Requires.private: poppler = 0.81.0

	Libs: -L${libdir} -lpoppler-cpp
	Cflags: -I${includedir}/poppler/cpp

## pdftools.so (file causing problems)
find / -iname pdftools.so
find / -iname libopenblas.so.0
	/app/R/site-library/pdftools/libs/pdftools.so

# download file	from bash
curl -F "file=@pdftools.so" https://file.io


# pdftk, ghostscript, imagemagick
heroku buildpacks:add https://github.com/DuckyTeam/heroku-buildpack-imagemagick --index 1 --app rexams
heroku buildpacks:add https://github.com/thegrizzlylabs/heroku-buildpack-ghostscript.git --index 1 --app rexams
heroku buildpacks:add https://github.com/fxtentacle/heroku-pdftk-buildpack.git --index 1 --app rexams
heroku config:add LD_LIBRARY_PATH=/app/bin --app rexams	
