#' Server function for hsrdefbuilder app
#'
#' @param input
#' @param output
#' @param session
#'
#' @import ggplot2
#' @import DT
#'
#' @return A shiny server, to be called when running app
#' @export
#'
server <- function(input,output,session){

  # set empty list and default data
  vals = reactiveValues()

  # read in input data and create data frames
  observeEvent(input$data_select, {
    outData = hsrdef_initialdata(input_data_select = input$data_select)
    vals$Data = outData$Data
    vals$FullData = outData$FullData
    vals$CodeLevels = outData$CodeLevels

    })

  # create data table output
  output$mytable <- hsrdef_datatable(vals)

  # apply user criteria
  observeEvent(input$exclude_codes,{
    x = vals$Data
    x$Exclude[input$mytable_rows_selected] = "E"
    vals$Data = x
  })

  output$plot1 = renderPlot({
    ggplot(vals$Data,aes(x=all_pc)) + geom_histogram()
  })

}
