## Rex: Shiny R/exams Dashboard <img src="https://raw.githubusercontent.com/guesswho1234/Rex/main/www/logo.svg" align="right" alt="Rex logo" width="180" />

This repository provides an interactive [shiny](https://shiny.posit.co/) dashboard
for creating and evaluating written multiple-choice exams. The underlying workhorse
is [R/exams](https://www.R-exams.org/), in particular the so-called
[NOPS exams](https://www.R-exams.org/tutorials/exams2nops/) which support both
single-choice and multiple-choice exercises along with automatic evaluation.

The dashboard provides:

- Import/export of R/exams exercises with type "schoice" or "mchoice"
- Creation of an exam by combining (blocks of) exercises and exporting (randomized) PDF files
- Evaluation scanned exercises
- Management of participants and grades, connecting with other tools at [Universität Innsbruck](https://www.uibk.ac.at/)

Rex is developed by [Sebastian Bachler](https://www.uibk.ac.at/ibf/team/bachler.html.en)
and is still work-in-progress.

To try out Rex make sure that you have all the necessary R packages installed, see `init.R`.
Then start the up in the base directory via `shiny::runApp()` and authenticate using `rex`
as both login and password.
