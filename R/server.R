#' Server function for hsrdefbuilder app
#'
#' @param input
#' @param output
#' @param session
#'
#' @import ggplot2
#' @import DT
#' @import tools
#'
#' @return A shiny server, to be called when running app
#' @export
#'
server <- function(input,output,session){


  # set empty list and default data -----------------------------------------

  vals = reactiveValues()

  # read in input data and create data frames ------------------------------

  observeEvent(input$data_select, {
    outData = hsrdef_initialdata(input_data_select = input$data_select)
    vals$Data = outData$Data
    vals$FullData = outData$FullData
    vals$CodeLevels = outData$CodeLevels

  })


  # create data table -------------------------------------------------------

  output$mytable <- hsrdef_datatable(vals$Data)


  # # apply user criteria -----------------------------------------------------
  #
  # ## excluded codes
  # observeEvent(input$exclude_codes,{
  #   x = vals$Data
  #   x$Exclude[input$mytable_rows_selected] = "E"
  #   vals$Data = x
  # })
  #
  # ## included codes
  # observeEvent(input$include_codes,{
  #   x = vals$Data
  #   x$Include[input$mytable_rows_selected] = "I"
  #   vals$Data = x
  # })
  #
  # ## remove criteria
  # observeEvent(input$clear_codes,{
  #   x = vals$Data
  #   x$Include[input$mytable_rows_selected] = ""
  #   x$Exclude[input$mytable_rows_selected] = ""
  #   vals$Data = x
  # })
  #
  # ## remove rows
  # observeEvent(input$drop_rows,{
  #   x = vals$Data
  #   x = x[!input$mytable_rows_selected,]
  #   vals$Data = x
  # })
  #
  # ## add label to rows
  # observeEvent(input$label_text,{
  #   vals$label_input = input$label_text
  # })
  #
  # observeEvent(input$label_codes,{
  #   x = vals$Data
  #   x_lab = vals$label_input
  #   x$Labels[input$mytable_rows_selected] = x_lab
  #   vals$Data = x
  # })
  #
  #
  # # create plot data --------------------------------------------------------
  # local_df = reactive({
  #
  #   df = hsrdrf_barplotdata(x = vals$value, data = vals$FullData,
  #                           code_levels = vals$CodeLevels)
  #
  #   df
  # })
  #
  # create plot outputs -----------------------------------------------------

  # output$plot1 = renderPlot({
  #   # ggplot(local_df(),aes(y=code,x=value,fill=name)) +
  #   #   geom_bar(stat="identity",position="stack",colour="black")
  #
  #   ggplot(vals$Data,aes(x=Exclude)) + geom_histogram(stat="count")
  # })
  # #
  # # upload saved user codes -------------------------------------------------
  # observeEvent(input$uploadCodes,{
  #   x = vals$Data
  #   outData = hsrdef_uploaddata(file = input$uploadCodes,old_data = x)
  #
  #   vals$Data = outData
  # }
  # )
  #
  # # download user selection -------------------------------------------------
  #
  # output$downloadData <- downloadHandler(
  #   filename = function() {
  #     paste0("def-", Sys.Date(), ".csv")
  #   },
  #   content = function(file) {
  #     write.csv(vals$Data, file, row.names = FALSE)
  #   }
  # )

}
