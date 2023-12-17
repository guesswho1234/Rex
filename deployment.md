# Poppler buildpack !!! not sure if this does the trick !!!
To be able to use the pdftools package we need poppler to be available.
For this we additionally need to add the following buildpack as well.

heroku cli command:
heroku buildpacks:add -a APP_NAME https://github.com/amitree/heroku-buildpack-poppler

# Heroku Buildpack !!! this works !!!
With init.R and run.R in place, we can push directly to Heroku.
However, we need to select a buildpack that tells Heroku how to handle the shiny app.
We use: https://github.com/virtualstaticvoid/heroku-buildpack-r

heroku cli command:
heroku buildpacks:set -a APP_NAME https://github.com/virtualstaticvoid/heroku-buildpack-r

# order is important
heroku buildpacks:set -a APP_NAME https://github.com/virtualstaticvoid/heroku-buildpack-r
heroku buildpacks:add --index 1 -a APP_NAME https://github.com/amitree/heroku-buildpack-poppler


# things i tried
find / -iname pkgconfig
	./tcltk/lib/pkgconfig
	./R/lib/pkgconfig
	./.apt/usr/lib/x86_64-linux-gnu/pkgconfig

find / -iname poppler-cpp.pc
	/app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/poppler-cpp.pc	
		~ $ cd /app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/
			~/.apt/usr/lib/x86_64-linux-gnu/pkgconfig $ dir
				poppler-cpp.pc  poppler-splash.pc  poppler.pc

find / -xdev 2>/dev/null -name "poppler"
	~ $ cd ./.apt/usr/include/poppler/cpp
		~/.apt/usr/include/poppler/cpp $ dir
			poppler-destination.h    poppler-font.h    poppler-page-renderer.h    poppler-rectangle.h
			poppler-document.h       poppler-global.h  poppler-page-transition.h  poppler-toc.h
			poppler-embedded-file.h  poppler-image.h   poppler-page.h             poppler-version.h

find / -iname poppler-cpp.pc
	/app/.apt/usr/lib/x86_64-linux-gnu/pkgconfig/poppler-cpp.pc





