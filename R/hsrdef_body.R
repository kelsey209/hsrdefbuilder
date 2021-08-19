#' Create main body of user interface for hsrdefbuilder app
#'
#' @return Input to dashboardBody
#' @importFrom DT dataTableOutput
#' @importFrom shinyBS bsTooltip
#' @importFrom graphics box
#' @importFrom shiny fluidRow column helpText actionButton textInput hr br h3 p h5 plotOutput fileInput downloadLink
#' @export
#'
hsrdef_body <- function(){

  # create set of action buttons and data table
  fluidRow(column(7,
                  box(width=12,
                      helpText("Select rows by clicking on them, then select an action.",
                               style="text-align:center"),
                      fluidRow(
                        column(12,offset = 0,
                               # action button: remove all user selections
                               column(2,actionButton("clear_codes","Clear criteria")),
                               bsTooltip("clear_codes",
                                         "Clear inclusion/exclusion selection",
                                         "right",
                                         options = list(container = "body")),

                               # action button: remove uninteresting rows
                               column(2,actionButton("drop_rows","Hide codes")),
                               bsTooltip("drop_rows","Hide selected row(s) - code not interesting.",
                                         "right",
                                         options = list(container = "body")),
                               column(2,
                                      # action button: add excluded codes
                                      actionButton("exclude_codes","Apply exclusions")),
                               bsTooltip("exclude_codes",
                                         "Creates an exclusion list from the selected row(s).",
                                         "right",
                                         options = list(container = "body")),
                               column(2,offset=0.2,
                                      # action button: add included codes
                                      actionButton("include_codes","Apply inclusions")),
                               bsTooltip("include_codes",
                                         "Creates an inclusion list from the selected row(s).",
                                         "right",
                                         options = list(container = "body")),
                               column(2,offset = 0.5,
                                      # let users create preliminary labels
                                      textInput("label_text","Enter label","",width = '1000px')),
                               column(2,
                                      actionButton("label_codes","Create label")),
                               bsTooltip("label_codes",
                                         "Add label to the selected row(s).",
                                         "right",
                                         options = list(container = "body"))
                      ),
                      #
                      hr(),
                      column(12,DT::dataTableOutput("mytable"))
                  )
                  )
  ),
  # create second column: graphs and user actions
  column(5,
         box(width=12,
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
             h5("Total counts of claims"),
             helpText("This shows the approximate proportion of total claims that meet the user's
                      definition. The Maybe category captures diagnosis combinations with masked counts."),
             br(),

             # PLOT output: bar chart
             column(12,plotOutput("plot2",height=30)),

             br(),
             br(),
             br(),

             hr(),

             # action buttons: let users upload previous data
             column(12,fileInput("uploadCodes",'Upload selections',multiple = FALSE)),
             bsTooltip("uploadCodes",
                       "Add previous inclusion or exclusion list.",
                       "right",options = list(container="body")),

             # action buttons: let users download their data
             column(12,downloadLink('downloadData','Click here to save definition')),
             bsTooltip("downloadData",
                       "Save your code selections.",
                       "right",options = list(container="body")),
             br(),
             br(),
             br()
         )
  )
  )
}




