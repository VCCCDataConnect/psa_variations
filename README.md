# Regional, Rural and Metropolitan variations in PSA testing and cancer outcomes

This repository contains all the code used to carry out analysis and generate results for the paper *Rural variations in primary care prostate cancer diagnosis and survival: A cohort study using linked Australian Primary Care Electronic Medical Record data* by Wawryk et al. currently under review.

## Structure of this repo

The code for all data cleaning, transformations and analysis are in the R and Stata do files. 

Data sources are described below. With the exception of the ABS datasets, these are only available upon request from the corresponding data providers.

The scripts section describes where to find the code for each of the analyses presented in the paper.

## Data sources

The project used the following data sources:

- Primary care encounters and PSA test results were extracted from the [Patron primary care database](https://medicine.unimelb.edu.au/school-structure/general-practice-and-primary-care/research/data-for-decisions)

- The [Victorian Cancer Registry](https://www.cancervic.org.au/research/vcr) was used to extract prostate cancer diagnoses and deaths

- [Australian Bureau of Statistics Census 2016](https://www.abs.gov.au/websitedbs/censushome.nsf/home/2016) for populations across SA2 areas in Victoria, Australia

- [Australian Bureau of Statistics Shapefiles](https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs-edition-3/jul2021-jun2026/access-and-downloads/digital-boundary-files) used to assign metropolitan, rural and regional classifications to each patient

## Scripts

Stata and R were used to carry out data cleaning, transformations and analysis.

### 1. Data cleaning and cohort creation

Primary care patients were drawn from the Patron primary care database. Some of the work was done in R and other parts in Stata

- `psa_data_cleaning.R`: extract all PSA results from the pathology table and join to patient table
- `ra_mapping.R`: create a mapping from SA2 codes to RA codes (to assign metro, rural and regional classification to each PSA patient)
-  `best_ra.R`: Extract the most suitable RA for each SA2 for those SA2's that overlap multiple RA's
- `VCR_cohort creation.do`: Stata code for extracting patients from VCR who were diagnosed with prostate cancer diagnoses, linked to Patron primary care data.
- `append_derived_columns.R`: Append the remoteness area values and PSA values to the VCR patron cohort

### 2. Descriptive statistics
- `vic_wide_visualisations.R`: bar charts comparing the Victorian population with the prostate cancer cohort, along with computing tables for the numbers of papers exceeding particular PSA thresholds, by regionality and time period.
- `box and whisper PSA diagnostic interval.R`: Creation of Figure 4
- `Phase 2_analysis_OW.do`: Association between diagnostic delay and gleason at diagnosis 
- `an1 descriptive analyses.do`: To create descriptive stats summarised in the tables  

### 3. Modelling
- `an2 diagnostic windows.do`: To create further descriptive stats on incidences as well as Poisson regression
- `Phase 2_analysis_OW_final.do`: Kaplan-Meier survival analyses 