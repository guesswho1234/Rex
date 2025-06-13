# Rex: Shiny R/exams Dashboard <img src="https://raw.githubusercontent.com/guesswho1234/Rex/main/www/logo.svg" align="right" alt="Rex logo" width="20%" />

This repository provides an interactive [Shiny](https://shiny.posit.co/) dashboard for creating and evaluating written single- or multiple-choice exams and building reusable exercise pools. The underlying workhorse is [R/exams](https://www.R-exams.org/), specifically the so-called [NOPS exams](https://www.R-exams.org/tutorials/exams2nops/) functions, which support both randomized single-choice and multiple-choice exercises along with automatic evaluation.

Rex is developed by [Sebastian Bachler](mailto:sbachler@gmx.at). Feel free to reach out if you have any questions.

## Demo

Full featured access to a hosted version and example files can be requested via e-mail.

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

Start up via:

```R
shiny::runApp(appDir = '<base directory containing app.R>', host = '0.0.0.0', port = 3838)
```
Alternatively, open and run `app.R` via RStudio.

### Docker

On the host, make the database file owned by the UID=1001 and GID=1001:

```bash
chown 1001:1001 /home/rex.sqlite
chmod 660 /home/rex.sqlite
```

Build and start the Docker infrastructure using the following command:

```bash
docker-compose -f compose_rex.yaml up --build
```

## Hosting

> [!CAUTION]
> This project uses a hardened Docker setup with non-root users, dropped capabilities, and resource limits.
> External access is restricted to the frontend only; the background worker has no network access.
> While these measures reduce risk, always audit images and dependencies before deploying to production.
> **Use at your own risk and follow best security practices.**

## Use

By default, use "rex" as both user and password to authenticate. 

It is recommended to use Rex in Firefox.

### Standard Workflow

#### Manage Exercises

The entire management of exercises takes place in the "EXERCISES" tab of the application.

When managing exercises, the following input fields can generally be edited:
- Name
- Author
- Type
- Points
- Section
- Question (accepts LaTeX code when "TeX mode" is switched on)
- Figure (accepts a single PNG file per exercise)
- Answers (consisting of the solution, answer text, and a solution note)

Beyond the user interface of Rex, exercises with more complexity (i.e., seed based exercise variations or exercises with R plots) can also be coded outside of Rex and are accepted as RNW and RMD files. However, these exercises are not editable within Rex. 

#### Create Exams

To create exams, navigate to the "EXAM" tab and then to "Create exam." There you will find a form with various options to set.

Before creating an exam, make sure that exercises in the exercise tab are marked as examinable.

When clicking the "Create exam" button, the exam will be created. Once this process is finished, a popup will appear, offering you to save the exam. When saving the exam, a ZIP archive will be downloaded. This archive will include the following files:
- All the exam scramblings as PDF files
- All the exam scramblings as HTML files, including solutions and solution notes
- An RDS file to evaluate the exam
- All of the exercises used in the exam
- A TXT file "input.txt" containing all the input values used for creating the exam
- A TXT file "code.txt" containing R code, which can be used to replicate the main output in R and without Rex

#### Evaluate Exams

To evaluate exams, navigate to the "EXAM" tab and then to "Evaluate exam." There you will find another form with various options to set.

Before the evaluation of an exam is possible, the following three files need to be prepared:
- "Solutions": the RDS file within the ZIP archive, which was supplied when the exam was created
- "Registered participants": a CSV file containing information about exam participants (optional; if not provided, dummy participants will be used)
- "Evaluation scans": all the evaluation sheet scans as either PDF files and/or PNG files (preferably all in the same orientation)

When clicking the "Evaluate exam" button, the exam will be evaluated. First, the scans are processed. When this is finished, a popup will appear, allowing you to inspect and manually edit any of the processed scans. After proceeding, the evaluation will be finalized. Once finished, another popup will appear offering the option to save the exam evaluation. When saving the evaluation, a ZIP archive will be downloaded. This archive will include the following files:
- Two ZIP archives: one (ending with "_nops_scan.zip") containing all the scans converted to PNG files, along with the extracted raw data, and another (ending with "_nops_eval.zip") containing the evaluation documents for each participant
- Two CSV files: one containing the registered participants and another (ending with "_nops_eval.csv") containing all the evaluation data ready to distribute to participants
- The RDS file used to evaluate the exam
- A TXT file "statistics.txt" containing some basic evaluation statistics
- A PDF file "nops_report.pdf" containing a statistical report of the evaluation (only provieded for >= 5 valid scans)
- A TXT file "input.txt" containing all the input values used for evaluating the exam
- A TXT file "code.txt" containing R code, which can be used to replicate the main output in R and without Rex

## Addons

Addons are a way to extend Rex with custom features, such as default values, additional input fields, or entirely new functionalities.

> [!CAUTION]
> Addons can introduce additional security risks.
> **Use at your own risk and follow best security practices.**
  
## Contribute

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
