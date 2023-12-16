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
heroku buildpacks:add -a APP_NAME https://github.com/amitree/heroku-buildpack-poppler

#try this from https://stackoverflow.com/questions/57998238/how-to-use-poppler-buildpack-on-heroku
Add the buildpack to Heroku:

heroku buildpacks:set -a APP_NAME https://github.com/virtualstaticvoid/heroku-buildpack-r
heroku buildpacks:add --a APP_NAME --index 1 heroku-community/apt

Make a file named Aptfile in your project folder and write 

	build-essential libpoppler-cpp-dev pkg-config python3-dev 

inside