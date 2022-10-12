# Health Services Research Definition Builder

## Overview 

This package is created for analysts starting a claims-based research project, requiring
a cohort definition using ICD diagnosis codes. 



![Diagram of workflow](docs/diagram.png)
_Figure: the proposed hsrdefbuilder workflow. Analysts run the hsrdefbuilder code on claims, and create a summary of the codes associated with that service. Collaborators and analysts can view this and use the hsrdefbuilder Shiny application to make decisions about which codes to include in their final cohort definition._



Users can select and investigate the diagnosis codes most associated with the service claims, 
and share this output with their collaborators outside of a SAS environment. 

The hsrdefbuilder package allows users to run our [Shiny R](https://shiny.rstudio.com/) 
application in their own R session. 

We built this application with a SAS to R workflow in mind, meaning the initial claims
selection and processing is done using a SAS program, while its output is processed and 
displayed using R. 

## Installation 

To install the hsrdefbuilder R package from github, run:

```
devtools::install_github("kelsey209/hsrdefbuilder")
```

The hsrdefbuilder shiny application can be run using the R function: 

```
hsrdefbuilder::runDefBuilder()
```

## Minimum dataset related to publication

The folder `minimum_dataset_paper` contains the output data from the SAS program for the services discussed in our submitted paper ([medRxiv link](https://doi.org/10.1101/2022.03.16.22272475)). 
- Table 2 was compiled from results that were output from running `hsrdef_run.SAS`. 
- Table 3 was based on the saved output data set from carrier claims with CPT code 29877: `results_table3_carrier29877.csv`.
- Table 4 results were compiled using the SAS code `hsrdef_run_urinalysis_check.R`. The datasets containing the important diagnosis codes listed in the table are: `results_table4_carrier81001.csv`, `results_table4_carrier81003.csv`, `results_table4_outpatient81001.csv`, `results_table4_outpatient81003.csv`). 
- Table 5 was created using the data set output from the SAS application with inpatient claims for procedure codes `0SG0x`: `results_table5_inpatient0SG0.csv`. 
