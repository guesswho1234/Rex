# Rex: Shiny R/exams Dashboard <img src="https://raw.githubusercontent.com/guesswho1234/Rex/main/www/logo.svg" align="right" alt="Rex logo" width="180" />

This repository provides an interactive [shiny](https://shiny.posit.co/) dashboard
for creating and evaluating written single and multiple-choice exams. The underlying workhorse
is [R/exams](https://www.R-exams.org/), in particular the so-called
[NOPS exams](https://www.R-exams.org/tutorials/exams2nops/) functions which support both
single-choice and multiple-choice exercises along with automatic evaluation.

The dashboard provides:

- Import/export of R/exams exercises with type "schoice" or "mchoice"
- Creation of an exam by combining (blocks of) exercises and exporting (randomized) PDF files
- Evaluation of scanned exercises
- Management of participants and grades, connecting with other tools at [Universität Innsbruck](https://www.uibk.ac.at/)

Rex is developed by [Sebastian Bachler](https://www.uibk.ac.at/ibf/team/bachler.html.en)
and is still work-in-progress.

## Run

There are multiple ways to get this applications running:

### Localhost

First, install all the necessary R packages (see `init.R`).

Second, make sure to have libsodium-dev and libpopppler-cpp-dev available on your system.

Third, start up in the base directory via `shiny::runApp()` or, alternatively, via RStudio by 
opening and running `app.R`.

### Heroku (heroku-22 stack, Dpkg and R (shiny) framework)

First, install the following buildpacks in this order on your heroku app:
- https://github.com/rricard/heroku-buildpack-dpkg.git
- https://github.com/virtualstaticvoid/heroku-buildpack-r

Second, set the following environment variables (called "*Config Vars*" on Heroku):
- `INCLUDE_DIR`: `/app/.dpkg/usr/include/poppler/cpp/`
- `LD_LIBRARY_PATH`: `/app/.dpkg/usr/lib/x86_64-linux-gnu/:/app/R/lib/R/lib:/app/tcltk/lib`
- `LIB_DIR`: `/app/.dpkg/usr/lib/x86_64-linux-gnu/`

Third, deploy this repository to your heroku app.

Fourth, make sure the web dyno is turned on.

> [!NOTE]
Heroku shuts down your application once it tries to use twice the memory allocated to your dyno type.
If you are using the `Eco` dyno type, the application also shuts down once there is no traffic for 30 minutes.

### Docker

First, build your image with the supplied docker file `Dockerfile`: `docker build --platform linux/x86_64 -t shiny-docker-rex .`.

Second, run your image: `docker run -p 8180:8180 shiny-docker-rex`. 

## Usage

Once you got the application running, authenticate using `rex` as both login and password.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what 
you would like to change.
