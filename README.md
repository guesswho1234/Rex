# Rex: Shiny R/exams Dashboard <img src="https://raw.githubusercontent.com/guesswho1234/Rex/main/www/logo.svg" align="right" alt="Rex logo" width="20%" />

This repository provides an interactive [shiny](https://shiny.posit.co/) dashboard
for creating and evaluating written single / multiple-choice exams and creating reusable exercise pools. The underlying workhorse
is [R/exams](https://www.R-exams.org/), in particular the so-called
[NOPS exams](https://www.R-exams.org/tutorials/exams2nops/) functions, which support both
randomized single-choice and multiple-choice exercises along with automatic evaluation.

Rex is developed by [Sebastian Bachler] and is still work-in-progress.

## System Resources

For Rex to operate properly, make sure the following resources are available. 

- libsodium-dev
- libmagick++-dev 
- libpoppler-cpp-dev
- ghostscript
- texlive-full
- pandoc

## Run

### Local
> [!WARNING]
> There currently is a bug where sometimes worker requests are not properly processed and the app gets stuck on the "please wait" overlay.
> Until fixed, an old version without the worker feature in the noWorker branch can be used.

Install all required R packages including their dependencies (see section "PACKAGES" in `app.R` and `worker.R`). 

Start up via `shiny::runApp(appDir = '<base directory containing app.R>', host = '0.0.0.0', port = 3838);` or, alternatively, via RStudio by 
opening and running `app.R`.

### Docker

Build your docker infrastructure with the supplied docker compose file by running `docker-compose -f compose_rex.yaml up`.

## Hosting
> [!CAUTION]
> Do not host this version of Rex with uncontrolled / public access and no additional security measures.
> Code from user input is parsed and evaluated by the `rex_worker` container.

## Use

By default use "rex" as both login and password to authenticate.

### Standard Workflow

#### Manage exercises

The entire management of exercises takes place in the "EXERCISES" tab of the application.

When managing exercise, the following input fields can be edited:
- Name
- Author
- Type
- Points
- Section
- Question (accepts LaTeX code when "TeX mode" is switched on)
- Figure (accepts a single PNG file per exercise)
- Answers (consisting of the solution, answer text, and a solution note)

On the top right of the exercises tab, summary information on all exercises that are marked as examinable is shown. 

#### Create exams

To create exams, navigate to the "EXAM" tab and further to "Create exam". There you will find a form with various options to set. 

Before creating an exam, make sure that exercises in the exercise tab are marked as examinable first.

When clicking the "Create exam" button the exam will be created. Once this process is finished, a popup will show and offer to save the exam. When saving the exam, a ZIP archive will be downloaded. In this archive the following files will be included:
- All the exam scramblings as PDF files
- All the exam scramblings as HTML files including solutions and solution notes
- A RDS file to evaluate the exam 
- All of the exercises used in the exam 
- A TXT file "input.txt" containing all the input values used for creating the exam

#### Evaluate exams

To evaluate exams, navigate to the "EXAM" tab and further to "Evaluate exam". There you will find another form with various options to set.

Before the evaluation of an exam is possible, the following three files need to be prepared:
- "Solutions": the supplied RDS file within the ZIP archive when the exam was created
- "Registered participants": a CSV file containing information of exam participants
- "Evaluation scans": all the evaluation sheet scans as either PDF files (all pages in the same orientation) and/or correctly oriented PNG files 

When clicking the "Evaluate exam" button the exam will be evaluated. At first scans are processed. When this is finished, a popup will show and allow to inspect and manually edit any of the processed scans. When proceeding, the evaluation is finalized. Once finished, again a popup will show and offer to save the exam evaluation. When saving the exam evaluation, a ZIP archive will be downloaded. In this archive the following files will be included:
- Two ZIP archives, one (ending with "_nops_scan.zip") containing all the scans converted to PNG files plus the extracted raw data and another (ending with "_nops_eval.zip") containing the evaluation documents of each participant.
- Two CSV files, one contsining the registered participants and another (ending with "_nops_eval.csv") containing all the evaluation data.
- The RDS file used to evaluate the exam
- A TXT file "statistics.txt" containing some basic evaluation statistics
- A TXT file "input.txt" containing all the input values used for evaluating the exam

## Contribute

Pull requests are welcome. For major changes, please open an issue first to discuss what 
you would like to change.
