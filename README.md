# Health Services Research Definition Builder

Update 2022-10-05: This package is currently under updates and may not work if downloaded using its current version. 

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
