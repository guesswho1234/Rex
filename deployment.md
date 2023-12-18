# Heroku Buildpack
With init.R and run.R in place, we can push directly to Heroku.
However, we need to select a buildpack that tells Heroku how to handle the shiny app.
We use: https://github.com/virtualstaticvoid/heroku-buildpack-r

heroku cli command:
heroku buildpacks:set -a APP_NAME https://github.com/virtualstaticvoid/heroku-buildpack-r

# Poppler buildpack
To be able to use the pdftools package we need poppler to be available.
For this we additionally need to add the following buildpack as well.

heroku cli command:
heroku buildpacks:add --index 1 -a APP_NAME https://github.com/amitree/heroku-buildpack-poppler

alternative:

heroku buildpacks:add --index 1 -a APP_NAME https://github.com/k16shikano/heroku-buildpack-poppler

# order of buildpacks is important - poppler should be first


# error when building
# INCLUDE_DIR = /app/.apt/usr/include/poppler/cpp
# PKG_CONFIG_PATH = /app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/
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

# run bash
C:\Users\User> heroku run bash -a rexams

# check and set path
~/R/site-library $ echo $PATH
	/app/R/lib/R/bin:/app/tcltk/bin:/app/pandoc/bin:/usr/local/bin:/usr/bin:/bin
~/R/site-library $ PATH="$PATH:/app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/"

# pkgconfig
find / -iname pkgconfig
	./tcltk/lib/pkgconfig
	./R/lib/pkgconfig
	./.apt/usr/lib/x86_64-linux-gnu/pkgconfig

find / -iname poppler-cpp.pc
	/app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/poppler-cpp.pc	
		~ $ cd /app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/
			~/.apt/usr/lib/x86_64-linux-gnu/pkgconfig $ dir
				poppler-cpp.pc  poppler-splash.pc  poppler.pc

# library
~ $ cd ./.apt/usr/lib/x86_64-linux-gnu/
	~/.apt/usr/lib/x86_64-linux-gnu $ dir
		libpoppler-cpp.so    libpoppler-cpp.so.0.7.0  libpoppler.so.91      pkgconfig
		libpoppler-cpp.so.0  libpoppler.so

# include
find / -xdev 2>/dev/null -name "poppler"
	~ $ cd ./.apt/usr/include/poppler/cpp
		~/.apt/usr/include/poppler/cpp $ dir
			poppler-destination.h    poppler-font.h    poppler-page-renderer.h    poppler-rectangle.h
			poppler-document.h       poppler-global.h  poppler-page-transition.h  poppler-toc.h
			poppler-embedded-file.h  poppler-image.h   poppler-page.h             poppler-version.h

# poppler-cpp.pc
find / -iname poppler-cpp.pc
	/app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/poppler-cpp.pc
	
~/.apt/usr/lib/x86_64-linux-gnu/pkgconfig $ cat poppler-cpp.pc
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
	





