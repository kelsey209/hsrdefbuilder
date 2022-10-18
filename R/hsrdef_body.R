#' Create main body of user interface for hsrdefbuilder app
#'
#' @return Input to dashboardBody
#' @importFrom DT dataTableOutput
#' @importFrom shinyBS bsTooltip
#' @importFrom shiny fluidRow column helpText actionButton textInput hr br h3 p h5 plotOutput fileInput downloadLink
#' @importFrom shinydashboard box
#' @export
#'
hsrdef_body <- function(){

  checkbox_script <- '$(document).on("click", "input", function () {
    var exc_checkboxes = document.getElementsByName("exc_selected");
    var inc_checkboxes = document.getElementsByName("inc_selected");
    var excCheckboxesChecked = [];
    var excCheckboxesDropped = [];
    var incCheckboxesChecked = [];
    var incCheckboxesDropped = [];
    for (var i=0; i<exc_checkboxes.length; i++) {
      if (exc_checkboxes[i].checked) {
        excCheckboxesChecked.push(exc_checkboxes[i].value);
        inc_checkboxes[i].checked = null;
        incCheckboxesDropped.push(inc_checkboxes[i].value);
      } else if (inc_checkboxes[i].checked) {
        incCheckboxesChecked.push(inc_checkboxes[i].value);
        exc_checkboxes[i].checked = null;
        excCheckboxesDropped.push(exc_checkboxes[i].value);
      } else {
        excCheckboxesDropped.push(exc_checkboxes[i].value);
        incCheckboxesDropped.push(inc_checkboxes[i].value);
      }
    }

    Shiny.onInputChange("checked_exc_rows",excCheckboxesChecked);
    Shiny.onInputChange("unchecked_exc_rows",excCheckboxesDropped);
    Shiny.onInputChange("checked_inc_rows",incCheckboxesChecked);
    Shiny.onInputChange("unchecked_inc_rows",incCheckboxesDropped);})'

  check_box_remove <- '$("#clear_codes").on("click", function () {
      var exc_checkboxes = document.getElementsByName("exc_selected");
      var inc_checkboxes = document.getElementsByName("inc_selected");
      for (var i=0; i<exc_checkboxes.length; i++) {
        exc_checkboxes[i].checked = null;
        inc_checkboxes[i].checked = null;
      }
    });'

  # create set of action buttons and data table
  fluidRow(column(7,
                  box(width = 12,
                      helpText("Please upload data using the options on the side panel. Users can then interact with the table below
                               to develop their cohort criteria. Users can also add their own labels to selected codes for their later reference.",
                               style = "text-align:left"),
                      fluidRow(
                        column(12,offset = 0,
                               # action button: remove all user selections
                               column(2,actionButton("clear_codes","Clear selections",
                                                     style = "background-color: #F5B7B1")),
                               bsTooltip("clear_codes",
                                         "Clear inclusion/exclusion criteria",
                                         "right",
                                         options = list(container = "body")),
                               # action button: remove uninteresting rows
                               column(2,actionButton("drop_rows","Hide codes",
                                                     style = "background-color: #F5B7B1")),
                               bsTooltip("drop_rows","Hide selected row(s) - code not interesting.",
                                         "right",
                                         options = list(container = "body")),

                               column(2,
                                      # action button: add excluded codes
                                      actionButton("exclude_codes","Exclude codes",
                                                   style = "background-color: #AED6F1")),
                               bsTooltip("exclude_codes",
                                         "Use selected row(s) as exclusion criteria.",
                                         "right",
                                         options = list(container = "body")),
                               column(2,
                                      # action button: add included codes
                                      actionButton("include_codes","Include codes",
                                                   style = "background-color: #AED6F1")),
                               bsTooltip("include_codes",
                                         "Use selected row(s) as inclusion criteria.",
                                         "right",
                                         options = list(container = "body")),
                               column(2,
                                      # let users create preliminary labels
                                      selectizeInput(inputId = "label_text",
                                                     label = tags$span(style = "color: #DC7633;","Input label"),
                                                     width = '1000px',
                                                     choices = vector(mode = "character"),
                                                     options = list(create = TRUE))),
                               column(2,
                                      actionButton("label_codes","Add label",
                                                   style = "background-color: #EDBB99")),
                               bsTooltip("label_codes",
                                         "Add label to the selected row(s).",
                                         "right",
                                         options = list(container = "body"))
                        ),
                        #
                        hr(),
                        column(12,DT::dataTableOutput("mytable"),
                               tags$script(HTML(checkbox_script)),
                               tags$script(HTML(check_box_remove)))
                      )
                  )
  ),
  # create second column: graphs and user actions
  column(5,
         box(width = 12,
             h3("Claims with selected criteria applied"),
             p("These displayed results should be treated as an approximation.
               Numbers are not reported since these are counts based on a sample of claims."),
             p("Users can download their definitions and use on their own claims.
               Our code is available for users to run on Medicare claims, if they have access.
               Alternatively, please contact us if their is a service you would like to collaborate on."),

             # PLOT output: bar chart
             hr(),
             h5("Claim counts organised by group"),
             helpText("Each claim is included once in the following counts. Diagnosis codes
               are organised by their importance (or association) with the service in the claims."),
             br(),
             column(12,plotOutput("plot1")),
             br(),
             h5("Total count of claims"),
             helpText("This shows the approximate proportion of total claims that met the user's
                      criteria. The Maybe category captures diagnosis combinations with masked counts."),
             br(),

             # PLOT output: bar chart
             column(12,plotOutput("plot2",height = 30)),

             br(),
             br(),
             br(),

             hr(),

             # action buttons: let users upload previous data
             p("Upload previously selected criteria to apply to the current data:"),
             column(12,fileInput("uploadCodes",'Upload selections',
                                 multiple = FALSE)),
             bsTooltip("uploadCodes",
                       "Add previous inclusion/exclusion list.",
                       "right",
                       options = list(container = "body")),

             # action buttons: let users download their data
             p("Download selected criteria:"),
             column(12,downloadLink('downloadData','Click here to save definition')),
             bsTooltip("downloadData",
                       "Save your code selections.",
                       "right",options = list(container = "body")),
             br(),
             br(),
             br()
         )
  )
  )
}




