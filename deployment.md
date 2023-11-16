# Heroku Buildpack
With init.R and run.R in place, we can push directly to Heroku.
However, we need to select a buildpack that tells Heroku how to handle the shiny app.
We use: https://github.com/virtualstaticvoid/heroku-buildpack-r

After creating a new project on Heroku, make sure to add the buildpack as a config var:
heroku config:set BUILDPACK_URL=https://github.com/virtualstaticvoid/heroku-buildpack-r.git -a <heroku_project_name>

That's it. Just push to Heroku.