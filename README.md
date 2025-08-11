# Fashion-Data-Analysis-(2024-2025)

> A reproducible data analysis project exploring fashion trends, sales, sustainability and consumer behaviour across European countries during 2024-2025.  
> Includes Python analysis scripts/notebooks and SQL used for data ingestion, cleaning, aggregation and reporting.


## Table of Contents
- [Introduction](#introduction)
- [Project Goals](#project-goals)
- [Repository Structure](#repository-structure)
- [Quickstart — Installation](#quickstart--installation)
- [Configuration](#configuration)
- [Data (sources & management)](#data-sources--management)
- [SQL folder & examples](#sql-folder--examples)
- [Notebooks & Python scripts](#notebooks--python-scripts)
- [Dependencies](#dependencies)
- [Results, outputs & reports](#results-outputs--reports)
- [Code style & contribution guide](#code-style--contribution-guide)
- [License](#license)
- [Acknowledgements & data sources](#acknowledgements--data-sources)

# Introduction
 This project is a reproducible analysis repository aimed at examining fashion industry indicators across European countries during 2024-2025. The codebase contains Python (ETL, analysis, modeling and visualization) and SQL (schema, ingestion and reporting queries). 
 
# Project Goals
- Clean and transform raw data for analysis.
- Perform exploratory data analysis (EDA) to surface key trends across segments and time.
- Build simple forecasting or classification models 
- Produce reproducible reports in notebook and visualizations for stakeholders.

# Repository Structure
- Fashion-Data-Analysis-(2024-2025)/
- ├─ dataset/
- │ ├─ productitems.csv
- │ └─ salesietm.csv
- ├ ─ code.py
- ├─ model.ipynb
- ├─ notebooks.ipynb
- ├─ fashion analysis.sql
- ├─ .env.example
- ├─ requirements.txt
- ├─ environment.yml
- └─ README.md


# Quickstart — Installation

## Prerequisites
- Python 3.10+ (recommended)
- PostgreSQL (or your chosen SQL engine) for SQL scripts (or SQLite for local dev)

## Clone & install

- git clone https://github.com/mid-works/Fashion-Data-Analysis-2024-2025.git
- cd Fashion-Data-Analysis-2024-2025
- python -m venv .venv
# mac / linux
source .venv/bin/activate

# windows (powershell)
- .venv\Scripts\Activate.ps1

- pip install -r requirements.txt

- conda env create -f environment.yml
- conda activate data-fashion-2025

# Configuration
- DATABASE_URL=postgresql://user:password@localhost:5432/data_fashion
- DATA_PATH=./data
- S3_BUCKET=your-s3-bucket-name            # if using S3
- AWS_ACCESS_KEY_ID=...
- AWS_SECRET_ACCESS_KEY=...

# Dependencies

- pandas>=1.5
- numpy>=1.24
- sqlalchemy>=1.4
- psycopg2-binary
- jupyterlab
- matplotlib
- seaborn
-scikit-learn
- pyyaml
- papermill
- black
- flake8
- python-dotenv


# License 
- MIT License — see LICENSE file.


# Acknowledgements & data sources
- kaggle [https://www.kaggle.com/datasets/danishbaariq/data-fashion-in-europe-2025](#kaggle)
