# dbt-bch-pipeline

This repository contains the data transformation layer and CI workflow for the BCH pipeline. It runs on top of the Google Cloud infrastructure provisioned by the companion Terraform repository and builds BigQuery models in the bch_stagin and bch_mart datasets.

This project implements two dbt layers:

Staging layer
  * reads from bigquery-public-data.crypto_bitcoin_cash.transactions
  * filters the data to the last three months
  * selects and renames the required transaction fields
  * materializes the result as a table in bch_staging

Mart layer
  * starts from the staging model
  * expands transaction inputs and outputs to the address level
  * computes received value, sent value, and current balance by address
  * excludes any address that has participated in a coinbase transaction
  * materializes the result as a table in bch_mart

  
The repository also includes a GitHub Actions workflow that authenticates to Google Cloud and runs dbt run automatically on pushes to main and on pull requests.

## Project Structure

* dbt_project.yml : dbt project configuration, including model paths and schema settings

* models/staging/stg_bch_transactions.sql : staging model built from the public BCH transactions dataset

* models/marts/mart_current_balance_by_address.sql : mart model computing current balance by address while excluding coinbase-related addresses

* packages.yml : dbt package configuration

* profiles.yml.example : example local dbt profile for BigQuery

* .github/workflows/dbt.yml :GitHub Actions workflow for CI execution

## Prerequisites

    Python 3.11
    pip
    dbt-bigquery
    access to a Google Cloud project with:
        * BigQuery enabled
        * dataset bch_staging
        * dataset bch_mart
    
    a Google Cloud service account with permission to:
        * read from bigquery-public-data.crypto_bitcoin_cash
        * create and update tables in bch_staging and bch_mart

## Deployement

### 1. Clone the repository
```bash
git clone <this-repo-url>
cd dbt-bch-pipeline
```

### 2. Install dbt
```bash
pip install --upgrade pip
pip install dbt-bigquery
```

### 3. Configure the dbt profile
Copy the example profile and update it with your GCP project, dataset, and authentication settings:
```bash
cp profiles.yml.example profiles.yml
```
The default schemas used by the project are:
* bch_staging for staging models
* bch_mart for mart models

### 4. Validate the connection
```bash
dbt debug --profiles-dir .
```

## Running the Project
Run all models:
```bash
dbt run --profiles-dir .
```

Run only the staging layer:
```bash
dbt run --select staging --profiles-dir .
```

Run only the mart layer:
```bash
dbt run --select marts --profiles-dir .
```

After a successful run, the following tables should be created:
* bch_staging.stg_bch_transactions
* bch_mart.mart_current_balance_by_address

## Transformation Logic

### Staging model
The staging model reads from bigquery-public-data.crypto_bitcoin_cash.transactions and filters records to the last three months using block_timestamp. It then selects and standardizes the fields needed downstream.

### Mart model
The mart model unnests transaction inputs and outputs to the address level, derives incoming and outgoing value movements, and aggregates them to compute the current balance by address. It also identifies addresses involved in coinbase transactions and excludes them from the final result.

## CI/CD
The GitHub Actions workflow in .github/workflows/dbt.yml runs on pushes to main and on pull requests targeting main.

The workflow:
* authenticates to Google Cloud using a service account
* installs dbt dependencies
* generates a profiles.yml file dynamically
* runs dbt deps
* runs dbt debug
* runs dbt run

### Required GitHub Secrets 
* `GCP_PROJECT_ID`
* `GCP_SERVICE_ACCOUNT_KEY_JSON`

The service account used in CI must have permission to read from the public BCH dataset and write to bch_staging and bch_mart.

## Infrastructure Dependency

This repository depends on the infrastructure created by the Terraform repository. That repository provisions the GCP project, enables BigQuery, creates the bch_staging and bch_mart datasets, and configures the service account used by this dbt project.


## Validation Summary

This solution was tested end to end using a personal Google Cloud billing account and local authenticated Google Cloud credentials.

Terraform validation included `terraform validate`, `terraform plan`, and `terraform apply`. The tests confirmed successful creation of the GCP project, BigQuery datasets (`bch_staging` and `bch_mart`), the `dbt-runner` service account, and the required IAM permissions.

dbt validation included `dbt debug`, `dbt deps`, `dbt compile`, and `dbt run`. The tests confirmed successful connection to BigQuery and successful materialization of the staging and mart models in the expected datasets.

Source data note: the public table `bigquery-public-data.crypto_bitcoin_cash.transactions` currently ends at `2024-05-13`. Because the challenge requires filtering to the last 3 months, the models build successfully but return 0 rows. 