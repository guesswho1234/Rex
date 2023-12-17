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

# order of buildpacks is important - poppler should be first

# error when building
remote:        foundpkgs: pdftools, /tmp/RtmpbKzL0T/downloaded_packages/pdftools_3.4.0.tar.gz        
remote:        files: /tmp/RtmpbKzL0T/downloaded_packages/pdftools_3.4.0.tar.gz        
remote:        * installing *source* package âpdftoolsâ ...        
remote:        ** package âpdftoolsâ successfully unpacked and MD5 sums checked        
remote:        ** using staged installation        
remote:        Found INCLUDE_DIR and/or LIB_DIR!        
remote:        Using PKG_CFLAGS=-I./.apt/usr/include/poppler/cpp -I/usr/include/poppler/cpp -I/usr/include/poppler        
remote:        Using PKG_LIBS=-L -lpoppler-cpp      
 
remote:        --------------------------- [ANTICONF] --------------------------------       
remote:        Configuration failed to find 'poppler-cpp' system library. Try installing:        
remote:         * rpm: poppler-cpp-devel (Fedora, CentOS, RHEL)        
remote:         * brew: poppler (MacOS)        
remote:         * deb: libpoppler-cpp-dev (Debian, Ubuntu, etc)        
remote:         * On Ubuntu 16.04 or 18.04 use this PPA:        
remote:            sudo add-apt-repository -y ppa:cran/poppler        
remote:            sudo apt-get update        
remote:            sudo apt-get install -y libpoppler-cpp-dev        
remote:        If poppler-cpp is already installed, check that 'pkg-config' is in your        
remote:        PATH and PKG_CONFIG_PATH contains a poppler-cpp.pc file. If pkg-config        
remote:        is unavailable you can set INCLUDE_DIR and LIB_DIR manually via:        
remote:        R CMD INSTALL --configure-vars='INCLUDE_DIR=... LIB_DIR=...'      
remote:        -------------------------- [ERROR MESSAGE] ---------------------------        
remote:        <stdin>:1:10: fatal error: poppler-document.h: No such file or directory        
remote:        compilation terminated.        
remote:        --------------------------------------------------------------------  

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
	





