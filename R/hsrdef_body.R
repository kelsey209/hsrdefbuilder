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
                      helpText("Select rows by clicking on them, then select an action.",
                               style = "text-align:center"),
                      fluidRow(
                        column(12,offset = 0,
                               # action button: remove all user selections
                               column(2,actionButton("clear_codes","Clear criteria")),
                               bsTooltip("clear_codes",
                                         "Clear inclusion/exclusion selection",
                                         "right",
                                         options = list(container = "body")),
                               column(2,
                                      # action button: add excluded codes
                                      actionButton("exclude_codes","Apply exclusions")),
                               bsTooltip("exclude_codes",
                                         "Creates an exclusion list from the selected row(s).",
                                         "right",
                                         options = list(container = "body")),
                               column(2,offset = 0.2,
                                      # action button: add included codes
                                      actionButton("include_codes","Apply inclusions")),
                               bsTooltip("include_codes",
                                         "Creates an inclusion list from the selected row(s).",
                                         "right",
                                         options = list(container = "body")),
                               # action button: remove uninteresting rows
                               column(2,actionButton("drop_rows","Hide codes")),
                               bsTooltip("drop_rows","Hide selected row(s) - code not interesting.",
                                         "right",
                                         options = list(container = "body")),
                               column(2,offset = 0.5,
                                      # let users create preliminary labels
                                      selectizeInput(inputId = "label_text",
                                                     "Enter label",
                                                     width = '1000px',
                                                     choices = vector(mode = "character"),
                                                     options = list(create = TRUE))),
                               column(2,
                                      actionButton("label_codes","Create label")),
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
               Alternatively, if you have a service you would like to collaborate on please contact us."),

             # PLOT output: bar chart
             hr(),
             h5("Claim counts organised by group"),
             helpText("Each claim is included once in the following counts. Diagnosis codes
               are organised by their importance (or association) with the service in the claims."),
             br(),
             column(12,plotOutput("plot1")),
             br(),
             h5("Total count of claims"),
             helpText("This shows the approximate proportion of total claims that meet the user's
                      definition. The Maybe category captures diagnosis combinations with masked counts."),
             br(),

             # PLOT output: bar chart
             column(12,plotOutput("plot2",height = 30)),

             br(),
             br(),
             br(),

             hr(),

             # action buttons: let users upload previous data
             p("Users can upload previously created definitions to apply to the current table."),
             column(12,fileInput("uploadCodes",'Upload selections',
                                 multiple = FALSE)),
             bsTooltip("uploadCodes",
                       "Add previous inclusion/exclusion list.",
                       "right",
                       options = list(container = "body")),

             # action buttons: let users download their data
             p("Users can download their developed definitions."),
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




