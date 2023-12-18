# Heroku Buildpack
With init.R and run.R in place, we can push directly to Heroku.
However, we need to select a buildpack that tells Heroku how to handle the shiny app.
We use: https://github.com/virtualstaticvoid/heroku-buildpack-r

heroku cli command:
heroku buildpacks:set -a rexams https://github.com/virtualstaticvoid/heroku-buildpack-r

# Poppler buildpack (order of buildpacks is important - poppler should be firs)
To be able to use the pdftools package we need poppler to be available.
For this we additionally need to add the following buildpack as well.

heroku cli command:
heroku buildpacks:add --index 1 -a rexams https://github.com/amitree/heroku-buildpack-poppler
heroku config:set -a rexams PKG_CONFIG_PATH=/app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig
heroku config:set -a rexams INCLUDE_DIR=/app/.apt/usr/include/poppler/cpp

# error when building https://github.com/amitree/heroku-buildpack-poppler
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


alternative:

heroku buildpacks:add --index 1 -a rexams https://github.com/k16shikano/heroku-buildpack-poppler
heroku config:set -a rexams PKG_CONFIG_PATH=/app/vendor/poppler/lib/pkgconfig/
heroku config:set -a rexams INCLUDE_DIR=/app/vendor/poppler/include/poppler/cpp/

heroku config:set -a rexams LIB_DIR=/app/vendor/poppler/lib/pkgconfig/poppler-cpp.pc
heroku config:set -a rexams INCLUDE_DIR=/app/vendor/poppler/include/poppler/cpp/

# error when building with https://github.com/k16shikano/heroku-buildpack-poppler
remote:        Installing package into â/app/R/site-libraryâ        
remote:        (as âlibâ is unspecified)        
remote:        system (cmd0): /app/R/lib/R/bin/R CMD INSTALL        
remote:        trying URL 'https://cloud.r-project.org/src/contrib/pdftools_3.4.0.tar.gz'        
remote:        Content type 'application/x-gzip' length 936466 bytes (914 KB)        
remote:        ==================================================        
remote:        downloaded 914 KB        
remote:                
remote:        foundpkgs: pdftools, /tmp/RtmpcDGPWm/downloaded_packages/pdftools_3.4.0.tar.gz        
remote:        files: /tmp/RtmpcDGPWm/downloaded_packages/pdftools_3.4.0.tar.gz        
remote:        * installing *source* package âpdftoolsâ ...        
remote:        ** package âpdftoolsâ successfully unpacked and MD5 sums checked        
remote:        ** using staged installation        
remote:        Package poppler-cpp was not found in the pkg-config search path.        
remote:        Perhaps you should add the directory containing `poppler-cpp.pc'        
remote:        to the PKG_CONFIG_PATH environment variable        
remote:        No package 'poppler-cpp' found        
remote:        Found INCLUDE_DIR and/or LIB_DIR!        
remote:        Using PKG_CFLAGS=-I/app/vendor/poppler/include/poppler/cpp/ -I/usr/include/poppler/cpp -I/usr/include/poppler        
remote:        Using PKG_LIBS=-L/app/vendor/poppler/lib/pkgconfig/ -lpoppler-cpp        
remote:        ** libs        
remote:        g++ -std=gnu++14 -I"/app/R/lib/R/include" -DNDEBUG -I/app/vendor/poppler/include/poppler/cpp/ -I/usr/include/poppler/cpp -I/usr/include/poppler -I'/app/R/site-library/Rcpp/include' -I/usr/local/include  -fvisibility=hidden -fpic  -g -O2  -c RcppExports.cpp -o RcppExports.o        
remote:        g++ -std=gnu++14 -I"/app/R/lib/R/include" -DNDEBUG -I/app/vendor/poppler/include/poppler/cpp/ -I/usr/include/poppler/cpp -I/usr/include/poppler -I'/app/R/site-library/Rcpp/include' -I/usr/local/include  -fvisibility=hidden -fpic  -g -O2  -c bindings.cpp -o bindings.o        
remote:        g++ -std=gnu++14 -shared -L/app/R/lib/R/lib -L/usr/local/lib -o pdftools.so RcppExports.o bindings.o -L/app/vendor/poppler/lib/pkgconfig/ -lpoppler-cpp -L/app/R/lib/R/lib -lR        
remote:        /bin/ld: cannot find -lpoppler-cpp: No such file or directory        
remote:        collect2: error: ld returned 1 exit status        
remote:        make: *** [/app/R/lib/R/share/make/shlib.mk:10: pdftools.so] Error 1        
remote:        ERROR: compilation failed for package âpdftoolsâ        
remote:        * removing â/app/R/site-library/pdftoolsâ        
remote:        * restoring previous â/app/R/site-library/pdftoolsâ     

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

# poppler-cpp.pc (https://github.com/amitree/heroku-buildpack-poppler)
find / -iname poppler-cpp.pc
	/app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/poppler-cpp.pc	
		~ $ cd /app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/
			~/.apt/usr/lib/x86_64-linux-gnu/pkgconfig $ dir
				poppler-cpp.pc  poppler-splash.pc  poppler.pc
				
# poppler-cpp.pc (https://github.com/k16shikano/heroku-buildpack-poppler)
find / -iname poppler-cpp.pc
	/app/vendor/poppler/lib/pkgconfig/poppler-cpp.pc			

# library
~ $ cd ./.apt/usr/lib/x86_64-linux-gnu/
	~/.apt/usr/lib/x86_64-linux-gnu $ dir
		libpoppler-cpp.so    libpoppler-cpp.so.0.7.0  libpoppler.so.91      pkgconfig
		libpoppler-cpp.so.0  libpoppler.so

# include (https://github.com/amitree/heroku-buildpack-poppler)
find / -xdev 2>/dev/null -name "poppler"
	~ $ cd ./.apt/usr/include/poppler/cpp
		~/.apt/usr/include/poppler/cpp $ dir
			poppler-destination.h    poppler-font.h    poppler-page-renderer.h    poppler-rectangle.h
			poppler-document.h       poppler-global.h  poppler-page-transition.h  poppler-toc.h
			poppler-embedded-file.h  poppler-image.h   poppler-page.h             poppler-version.h

# include (https://github.com/k16shikano/heroku-buildpack-poppler)
find / -xdev 2>/dev/null -name "poppler"
	/usr/share/poppler

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
	