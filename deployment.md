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




