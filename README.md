# Rex: Shiny R/exams Dashboard <img src="https://raw.githubusercontent.com/guesswho1234/Rex/main/www/logo.svg" align="right" alt="Rex logo" width="20%" />

This repository provides an interactive [Shiny](https://shiny.posit.co/) dashboard for creating and evaluating written single- or multiple-choice exams and building reusable exercise pools. The underlying workhorse is [R/exams](https://www.R-exams.org/), specifically the so-called [NOPS exams](https://www.R-exams.org/tutorials/exams2nops/) functions, which support both randomized single-choice and multiple-choice exercises along with automatic evaluation.

Rex is developed by [Sebastian Bachler] and is still a work in progress.

## System Resources

For Rex to operate properly, make sure that the following resources are available on your system:

- `libsodium-dev`
- `libmagick++-dev`
- `libpoppler-cpp-dev`
- `ghostscript`
- `texlive-full`
- `pandoc`

## Run

### Local

Install all required R packages, including their dependencies (see the "PACKAGES" section in `app.R` and `worker.R`).

Start up via `shiny::runApp(appDir = '<base directory containing app.R>', host = '0.0.0.0', port = 3838)` or, alternatively, via RStudio by opening and running `app.R`.

### Docker

Build your Docker infrastructure with the supplied Docker Compose file by running `docker-compose -f compose_rex.yaml up`.

## Hosting

> [!CAUTION]
> Do not host this version of Rex with uncontrolled or public access and no additional security measures.
> Code from user input is parsed and evaluated by the `rex_worker` container.

## Use

By default, use "rex" as both user and password to authenticate.

### Standard Workflow

#### Manage Exercises

The entire management of exercises takes place in the "EXERCISES" tab of the application.

When managing exercises, the following input fields can be edited:
- Name
- Author
- Type
- Points
- Section
- Question (accepts LaTeX code when "TeX mode" is switched on)
- Figure (accepts a single PNG file per exercise)
- Answers (consisting of the solution, answer text, and a solution note)

On the top right of the Exercises tab, summary information on all exercises that are marked as examinable is shown.

#### Create Exams

To create exams, navigate to the "EXAM" tab and then to "Create exam." There you will find a form with various options to set.

Before creating an exam, make sure that exercises in the exercise tab are marked as examinable.

When clicking the "Create exam" button, the exam will be created. Once this process is finished, a popup will appear, offering you to save the exam. When saving the exam, a ZIP archive will be downloaded. This archive will include the following files:
- All the exam scramblings as PDF files
- All the exam scramblings as HTML files, including solutions and solution notes
- An RDS file to evaluate the exam
- All of the exercises used in the exam
- A TXT file "input.txt" containing all the input values used for creating the exam
- A TXT file "code.txt" containing R code, which can be used to replicate the output without Rex

#### Evaluate Exams

To evaluate exams, navigate to the "EXAM" tab and then to "Evaluate exam." There you will find another form with various options to set.

Before the evaluation of an exam is possible, the following three files need to be prepared:
- "Solutions": the RDS file within the ZIP archive, which was supplied when the exam was created
- "Registered participants": a CSV file containing information about exam participants (if this file is not provided, dummy participants will be used in the evaluation process)
- "Evaluation scans": all the evaluation sheet scans as either PDF files (all pages in the same orientation) or correctly oriented PNG files

When clicking the "Evaluate exam" button, the exam will be evaluated. First, the scans are processed. When this is finished, a popup will appear, allowing you to inspect and manually edit any of the processed scans. After proceeding, the evaluation will be finalized. Once finished, another popup will appear offering the option to save the exam evaluation. When saving the evaluation, a ZIP archive will be downloaded. This archive will include the following files:
- Two ZIP archives: one (ending with "_nops_scan.zip") containing all the scans converted to PNG files, along with the extracted raw data, and another (ending with "_nops_eval.zip") containing the evaluation documents for each participant
- Two CSV files: one containing the registered participants and another (ending with "_nops_eval.csv") containing all the evaluation data
- The RDS file used to evaluate the exam
- A TXT file "statistics.txt" containing some basic evaluation statistics
- A TXT file "input.txt" containing all the input values used for evaluating the exam
- A TXT file "code.txt" containing R code, which can be used to replicate the output without Rex

## Addons

Addons are a way to extend Rex with custom features, such as default values, additional input fields, or entirely new functionalities.

> [!CAUTION]
> Addons can introduce additional security risks.
  
## Contribute

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
