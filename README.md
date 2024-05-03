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
- [optional addon] Management of participants and grades, connecting with other tools at [Universität Innsbruck](https://www.uibk.ac.at/)

Rex is developed by [Sebastian Bachler](https://www.uibk.ac.at/ibf/team/bachler.html.en)
and is still work-in-progress.

## Run

There are multiple ways to get this applications running:

### Localhost

Install all the necessary R packages (see `init.R`) including their dependencies.

Start up via `shiny::runApp(appDir = 'base directory containing app.R', host = '127.0.0.1', port = 8180);` or, alternatively, via RStudio by 
opening and running `app.R`.

### Heroku
This setup was tested on the `heroku-22` stack.

Install the following buildpacks in the following order on your heroku app:
- https://github.com/rricard/heroku-buildpack-dpkg.git
- https://github.com/virtualstaticvoid/heroku-buildpack-r

Set the following environment variables (called "*Config Vars*" on Heroku):
- `INCLUDE_DIR`: `/app/.dpkg/usr/include/poppler/cpp/`
- `LD_LIBRARY_PATH`: `/app/.dpkg/usr/lib/x86_64-linux-gnu/:/app/R/lib/R/lib:/app/tcltk/lib`
- `LIB_DIR`: `/app/.dpkg/usr/lib/x86_64-linux-gnu/`

Deploy this repository to your Heroku app.

Make sure the web dyno is turned on.

> [!NOTE]
Heroku shuts down your application if you exceed the memory allocated to your dyno type.
If you are using the `Eco` dyno type, the application also shuts down when there is no traffic for 30 minutes.

> [!WARNING]
While most features of Rex can be used with the low tier dyno types Heroku offers, evaluating exams cannot.
Therefore, make sure to switch to high performance dyno types if you wish to evaluate exams with Rex hosted on Heroku.  

### Docker

Build your image with the supplied docker file: `docker build --platform linux/x86_64 -t shiny-docker-rex .`.

Run your image: `docker run -p 8180:8180 shiny-docker-rex`. 

## Usage

Once you got the application running, authenticate using `rex` as both login and password. This then brings you to the
main application. At the very top, you will find a navigation bar with the following functionalities:
- Rex logo (click to get to the top of the page)
- `EXERCISES` tab where exercises are managed
- `EXAM` tab where exams are created and evaluated
- `TOOLS` tab where any additional addons are located
- `TeX mode` button to enable or disable LaTeX input mode (when turned on, fields where LaTeX is accepted will appear with a pink border) 
- `Hotkeys` button to enable or disable all hotkeys for the application (when hovered, overlays buttons with the corresponding hotkey mapping)
- Switch for displaying buttons with icons or text
- Switch to change the application language 
- Heart icon to indicate the application connection status
- `Log out` button to log out

At the very bottom you find all the information regarding source code and licensing.

### Workflow

Generally, the intended workflow of using the application can be separated into 3 parts:
1. [Manage exercises](#manage-exercises)
2. [Create exams](#create-exams)
3. [Evaluate exams](#evaluate-exams)

#### Manage exercises

The entire management of exercises takes place in the `Exercises` tab of the application. For all exercises the app 
distinguishes between `simple` editable exercises (highlighted with purple accents) and `complex` not editable exercises. Based on that, various 
functionalities are enabled or disabled. 

All together, the following functionalities for exercises exist:
- Change seed value used for random processes in `complex exercises`
- Create new `simple exercise` from scratch. 
- Import one or multiple existing `simple exercises` and `complex exercises` either as `*.rnw` or `*.rmd` files
- Save exercises 
- Convert `complex exercises` to `simple exercises`
- Parse exercises (i.e., check if everything is still fine)
- Mark exercises as examinable / add them to be considered for the exam
- Remove exercises
- Filter exercises
- Reorder exercises
- Group exercises into blocks to equally draw from when creating exams

Beyond that, as mentioned above, `simple exercise` can be edited directly within the application. When editing an exercise, the following
fields can be modified:
- Name
- Author
- Type
- Points
- Section
- Question (accepts LaTeX code when `TeX mode` is turned on)
- Figure
- Answers (consisting of the solution, text, and a solution note)

Data of fields with a yellow background shade will generally be observable by exam participants. Data of fields without this yellow background shade will never be observable by exam participants.
Once a field is edited, the exercise is automatically market with a red warning and, therefore, requires to be parsed again before it can be saved or marked as examinable.

Additionally, on the top right of the exercises tab, summary information on all exercises that are marked as examinable is shown. 

#### Create exams

To create exams, navigate to the `EXAM` tab and further to `Create exam`. There you will find one large form with various options to set. The following fields are available in this form:
- Exam date
- Seed (used for randomization of exercises, answers s well as random processes within exercises)
- Number of scramblings
- number of exercises
- Fix exercise order
- Fixed points per exercise
- Registration number digits
- Show points
- Duplex printing
- Replacement evaluation sheet
- Avoid wrap in choice list
- New page per exercise
- Language
- Institution
- Title
- Course
- Intro (accepts LaTeX code when `TeX mode` is turned on)
- Number of blank pages
- Additional Pdf pages

Input fields that are empty do not require values and are optional. All other fields do require explicit input values and are not optional. 
While initialized with the value 0, obviously, the `number of exercises` must be greater than 0 in order to be able to create an exam. 
To set a different number than 0, however, requires exercises to be marked as examinable. In other words, the maximum number of exercises in an exam is the number of exercises marked as examinable.

When pressing the `Create exam` button the exam creation process starts. When this process ends, a popup will show and, given that no errors where encountered, offer to save the exam. When saving the exam, a ZIP archive will be downloaded. In this archive you will find the following files:
- A PDF file for each scrambling including the evaluation sheet with the institution title, and course text, the intro text, set number of blank pages, and any additionally added PDF pages 
- A HTML file for each scrambling including the solutions and solution notes
- A RDS file which is needed to evaluate the exam later 
- All of the exercises used in the exam 
- A TXT file `input.txt` containing all the input values used for creating the exam

#### Evaluate exams

To evaluate exams, navigate to the `EXAM` tab and further to `Evaluate exam`. There you will find another large form with various options to set. The following fields are available in this form:
- Fixed points per exercise
- Registration number digits
- Partial points
- Rule for point deductions
- Negative points
- Grade exams
- Grading key
- Language
- Rotate scans
- Solutions
- Registered participants
- Evaluation scans

Input fields that are empty as well as the `Grading key` fields when `Grade exams` is not checked do not require values and are optional. All other fields plus the fields `Solutions`, `Registered participants`, and `Evaluation scans` do require explicit input values. Specifically:
- `Solutions`: the supplied RDS file in the ZIP archive downloaded when the exam was created
- `Registered participants`: a CSV file containing all the information of participants
- `Evaluation scans`: all the evaluation sheet scans as either PDF or PNG files

When pressing the `Evaluate exam` button the exam evaluation process starts. In a first stage, all the supplied scans are processed. Once this first stage is finished, a popup will show and, given that no errors where encountered, allow to inspect and edit all the scans together with the information extracted from them. When proceeding, the second and last stage starts. Once also this stage is finished, again a popup will show and, given that no errors where encountered, offer to save the exam evaluation. Also, it is possible to revert back to the first stage again. When saving the exam evaluation, a ZIP archive will be downloaded. In this archive you will find the following files:
- Two ZIP archives, one containing the scans as PNG files matching what was supplied for the `Evaluation scans` field (ending with `_nops_scan.zip`) and another containing the evaluation documents of the participants (ending with `_nops_eval.zip`). For each participant the evaluation document is further placed in a separate folder named after what was supplied in the `id` column of the file supplied for the `Registered participants` field
- Two CSV files, one machting what was supplied for the `Registered participants` field and another containing all the evaluation data (ending with `_nops_eval.csv`)
- One RDS file matching what was supplied for the `Solutions` field
- A TXT file `statistics.txt` containing some basic evaluation statistics of the exam 
- A TXT file `input.txt` containing all the input values used for evaluating the exam

### Addons

Addons are a way to add custom functionalities to the application that do not necessarily tie into the standard workflow described above.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what 
you would like to change.
