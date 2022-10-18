#' Create side-bar in shiny app ui
#'
#' @return side-bar to include in user interface
#'
#' @importFrom shinydashboard dashboardSidebar
#' @importFrom shiny h3 p br h4 fileInput
#'
#' @export
hsrdef_sidebar <- function(){
  dashboardSidebar(
    h3("Definition builder"),
    p("This tool lets users investigate diagnoses codes associated with selected services in Medicare claims.
                  Users can select diagnosis codes to exclude or include for their desired definition.
                  The right panel shows the estimated count of claims that meet the user's definition."),
    br(),
    h4("Data upload"),
    p("Users can load the example data (for 2016 carrier claims with CPT code 29879), or upload their own SAS data output."),
    br(),
    actionButton("load_example","Load example data"),
    br(),
    fileInput("data_select",'Upload SAS output',multiple = FALSE),
    p("Created by Kelsey Chalmers, Lown Institute with project support by Arnold Ventures."),
    br(),
    p("For code and submitting suggestions visit github.com/kelsey209.")
  )
}
