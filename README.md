# Rex: Shiny R/exams Dashboard <img src="https://raw.githubusercontent.com/guesswho1234/Rex/main/www/logo.svg" align="right" alt="Rex logo" width="180" />

This repository provides an interactive [shiny](https://shiny.posit.co/) dashboard
for creating and evaluating written single and multiple-choice exams. The underlying workhorse
is [R/exams](https://www.R-exams.org/), in particular the so-called
[NOPS exams](https://www.R-exams.org/tutorials/exams2nops/) functions which support both
single-choice and multiple-choice exercises along with automatic evaluation.

Rex is developed by [Sebastian Bachler](https://www.uibk.ac.at/ibf/team/bachler.html.en)
and is still work-in-progress.

## Run

### Localhost

Install all the necessary R packages (see `init.R`) including their dependencies.

Start up via `shiny::runApp(appDir = 'base directory containing app.R', host = '127.0.0.1', port = 8180);` or, alternatively, via RStudio by 
opening and running `app.R`.

### Heroku

Install the following buildpacks in the following order on your heroku app:
- https://github.com/rricard/heroku-buildpack-dpkg.git
- https://github.com/virtualstaticvoid/heroku-buildpack-r

Set the following environment variables (called "*Config Vars*" on Heroku):
- `INCLUDE_DIR`: `/app/.dpkg/usr/include/poppler/cpp/`
- `LD_LIBRARY_PATH`: `/app/.dpkg/usr/lib/x86_64-linux-gnu/:/app/R/lib/R/lib:/app/tcltk/lib`
- `LIB_DIR`: `/app/.dpkg/usr/lib/x86_64-linux-gnu/`

Deploy this repository to your Heroku app and make sure the web dyno is turned on.

> [!NOTE]
This setup was tested on the "heroku-22" stack.

> [!NOTE]
Heroku shuts down your application if you exceed the memory allocated to your dyno type.
If you are using the "Eco" dyno type, the application also shuts down when there is no traffic for 30 minutes.

> [!WARNING]
While most features of Rex can be used with the low tier dyno types Heroku offers, evaluating exams cannot.
Therefore, make sure to switch to high performance dyno types if you wish to evaluate exams with Rex hosted on Heroku.  

### Docker

Build your image with the supplied docker file: `docker build --platform linux/x86_64 -t shiny-docker-rex .`.

Run your image: `docker run -p 8180:8180 shiny-docker-rex`. 

## Use

Once you got the application running, authenticate using "rex" as both login and password.

### Workflow

#### Manage exercises

The entire management of exercises takes place in the "EXERCISES" tab of the application. For all exercises the app 
distinguishes between simple editable exercises (highlighted with purple accents) and complex exercises that are not editable. Based on that, various functionalities are enabled or disabled.

When editing sinple exercise, the following fields can be edited:
- Name
- Author
- Type
- Points
- Section
- Question (accepts LaTeX code when "TeX mode" is turned on)
- Figure
- Answers (consisting of the solution, text, and a solution note)

Data of fields with a yellow background shade will generally be observable by exam participants. Data of fields without this yellow background shade will never be observable by exam participants.
Once a field is edited, the exercise is automatically market with a red warning, requiring it to be parsed again before it can be saved or marked as examinable.

On the top right of the exercises tab, summary information on all exercises that are marked as examinable is shown. 

#### Create exams

To create exams, navigate to the "EXAM" tab and further to "Create exam". There you will find a form with various options to set. 

Input fields that are empty are optional. To set the number of exercises to a value greater than zero, exercises must be marked as examinable.

When pressing the "Create exam" button the exam crestion process starts. When this process is finished, a popup will show and, given that no errors were encountered, offer to save the exam. When saving the exam, a ZIP archive will be downloaded. In this archive you will find the following files:
- All the exam scramblings as PDF files
- All the exam scramblings as HTML files including the solutions and solution notes
- A RDS file to evaluate the exam 
- All of the exercises used in the exam 
- A TXT file "input.txt" containing all the input values used for creating the exam

#### Evaluate exams

To evaluate exams, navigate to the "EXAM" tab and further to "Evaluate exam". There you will find another form with various options to set.

Input fields that are empty as well as the "Grading key" fields when "Grade exams" is not checked do not are optional. All other fields plus the fields "Solutions", "Registered participants", and "Evaluation scans" do require explicit input values. Specifically:
- "Solutions": the supplied RDS file in the ZIP archive downloaded when the exam was created
- "Registered participants": a CSV file containing all the information of participants
- "Evaluation scans": all the evaluation sheet scans as either PDF files in the same orientation

When pressing the "Evaluate exam" button the exam evaluation process starts. In a first stage, all the supplied scans are processed. Once this first stage is finished, a popup will show and, given that no errors where encountered, allow to inspect and edit all the scans together with the information extracted from them. When proceeding, the second and last stage starts. Once also this stage is finished, again a popup will show and, given that no errors where encountered, offer to save the exam evaluation. Also, it is possible to revert back to the first stage again. When saving the exam evaluation, a ZIP archive will be downloaded. In this archive you will find the following files:
- Two ZIP archives, one containing all the scans as PNG files (ending with "_nops_scan.zip") and another containing the evaluation documents of each participant (ending with "_nops_eval.zip").
- Two CSV files, one contsining the registered participants and another containing all the evaluation data (ending with "_nops_eval.csv")
- The RDS file used to evaluate the exam
- A TXT file "statistics.txt" containing some basic evaluation statistics of the exam 
- A TXT file "input.txt" containing all the input values used for evaluating the exam

### Addons

Addons add custom functionalities to the application, which do not necessarily tie into the standard workflow described above.

## Contribute

Pull requests are welcome. For major changes, please open an issue first to discuss what 
you would like to change.
