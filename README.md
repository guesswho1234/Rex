# Rex: Shiny R/exams Dashboard <img src="https://raw.githubusercontent.com/guesswho1234/Rex/main/www/logo.svg" align="right" alt="Rex logo" width="20%" />

**Rex** is an easy-to-use [Shiny](https://shiny.posit.co/) dashboard for creating, managing, and evaluating written paper exams using [R/exams](https://www.R-exams.org/). It is designed to simplify workflows for educators while supporting complex, randomized exercise formats and fully automated evaluation.

---

## Demo 

Access to a hosted demo version is free and available on request via email for testing and evaluation purposes.

---

## System Requirements

Ensure the following system dependencies are available:

- `libsodium-dev`
- `libmagick++-dev`
- `libpoppler-cpp-dev`
- `ghostscript`
- `texlive-full`
- `pandoc`

---

## Getting Started

### Docker

#### Initial Setup
Download the database file `rex.sqlite` to your `/home/` directory using `curl` or `wget` (you may need `sudo` to write to `/home`):

```bash
# Using curl
curl -L -o /home/rex.sqlite https://raw.githubusercontent.com/guesswho1234/Rex/main/rex.sqlite
```

```bash
# Using wget
wget -O
```

Alternatively, you can manually download and place it in your `/home/` directory. 

#### Set File Ownership and Permissions

Ensure the database file is owned by UID `1001` and GID `1001`:

```bash
sudo chown 1001:1001 /home/rex.sqlite
sudo chmod 660 /home/rex.sqlite
```

#### Build and Run the Application

```bash
docker-compose -f compose_rex.yaml up --build
```

### Local (not recommended)

Install required R packages as listed in `app.R` and `worker.R`.

Then launch the app via:

```R
shiny::runApp(appDir = '<base directory containing app.R>', host = '0.0.0.0', port = 3838)
``` 

> ⚠️ Depending on your OS and availability of dependencies, the app might be bugged or not run at all. In that case use docker instead (see previous section).

---

## Security
 
Rex uses a hardened Docker setup:
- Non-root users with dropped capabilities  
- Background worker has no network access  
- Resource-limited containers  

> ⚠️ Always audit third-party dependencies before deployment. **Use at your own risk and follow security best practices.**

---

## Authentication

Rex supports:
- **Basic login** (default user: `rex`, password: `rex`)
- **Single Sign-On (SSO)** integration for OAuth 2.0 (configurable for institutional environments)

---

## Usage

> **Browser recommendation**: Firefox

### Manage Exercises

Use the **“EXERCISES”** tab to manage exercises.

Rex supports two types of exercises:

#### 1. **Simple Exercises**  
These are created directly within the app using the UI. Ideal for users without programming experience.

- Fully editable in the app
- Supports inline math and full LaTeX environments
- Fields include:
  - Name, Author, Type, Points, Section
  - Question text and solution note
  - Answer options with true/false flags and notes
  - One PNG figure per exercise
  - Toggle LaTeX environments
- Can be **exported** to `.RMD` or `.RNW` format and later **re-imported** without losing editability

#### 2. **Advanced (Coded) Exercises**  
These are authored externally in `.RMD` or `.RNW` files using R features such as:

- Dynamic code chunks (e.g. random number generation)
- Custom LaTeX environments
- Arbitrary R logic for exercise generation

These exercises can be **imported** into Rex, but **cannot be edited** directly in the UI.
  
> ⚠️ You may optionally convert advanced exercises to simple ones for editing, but this can lead to **loss of functionality or formatting**.

---

### Create Exams

Go to **“EXAM” > “Create exam”** to generate an exam.

Steps:
1. Ensure exercises are marked as *examinable*.
2. Configure options and click **“Create exam”**.
3. Download the generated ZIP archive, which includes:
   - **PDF files** of all exam versions — intended for **printing and distribution** to students
   - **HTML files** matching the PDF versions — include solutions and are meant for **quality control before the exam**
   - **RDS file** for later evaluation
   - All exercises used in the exam
   - `input.txt` — contains all parameter values used for exam creation
   - `code.txt` — R code to reproduce the exam outside of Rex

---

### Evaluate Exams

Navigate to **“EXAM” > “Evaluate exam”**.

Required files:
- **Solutions**: RDS file from exam creation
- **Participants**: CSV (optional; dummy users will be used if omitted)
- **Scans**: PDF or PNG of evaluation sheets (same orientation recommended)

After evaluation:
- Manual review/editing of scans is possible
- Output ZIP includes:
  - Converted scans (`*_nops_scan.zip`)
  - Individual evaluation reports (`*_nops_eval.zip`)
  - Overall evaluation CSV
  - PDF report and raw statistics
  - `input.txt` and `code.txt`

---

## Addons

Extend Rex with custom features like:
- Default values
- Additional UI fields
- Entirely new logic modules

> ⚠️ Addons may increase attack surface. **Use at your own risk.**

## Commercial hosting 

Dedicated deployment options and managed instances may be possible on request and can be discussed via email.

---
