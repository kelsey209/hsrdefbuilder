#' Server function for hsrdefbuilder app
#'
#' @param input ui input
#' @param output plot and table outputs
#' @param session shiny server session
#'
#' @importFrom ggplot2 ggplot aes geom_bar scale_fill_manual labs theme_minimal theme geom_rect theme_void coord_flip element_blank
#' @importFrom DT renderDataTable datatable
#' @importFrom utils head write.csv
#' @importFrom shiny reactiveValues observeEvent reactive renderPlot downloadHandler
#' @import data.table
#'
#' @return A shiny server, to be called when running app
#' @export
#'
server <- function(input,output,session){


  # set empty list and default data -----------------------------------------

  vals = reactiveValues()
  vals$PlotsActive = FALSE

  # read in input data and create data frames ------------------------------

  observeEvent(input$data_select, {
    outData = hsrdef_initialdata(input_data_select = input$data_select)
    vals$Data = outData$Data
    vals$FullData = outData$FullData
    vals$CodeLevels = outData$CodeLevels
    vals$PlotsActive = TRUE
  })

  ## up to here !
  observeEvent(input$checked_exc_rows,{
    print(input$checked_exc_rows)})

  observeEvent(input$checked_inc_rows,{
    print(input$checked_inc_rows)})

  # create data table -------------------------------------------------------

  output$mytable <- DT::renderDataTable({
    DT::datatable(hsrdef_datatable(vals$Data),
                  escape = FALSE,
                  rownames = FALSE,
                  options = list(pageLength = 20),
                  selection = "none")},
    server = FALSE)

  # # apply user criteria -----------------------------------------------------

  ## excluded codes
  # observeEvent(input$exclude_codes,{
  #   x = vals$Data
  #   x$Exclude[input$mytable_rows_selected] = "E"
  #   vals$Data = x
  # })

  ## included codes
  observeEvent(input$include_codes,{
    x = vals$Data
    x$Include[input$mytable_rows_selected] = "I"
    vals$Data = x
  })

  ## remove criteria
  observeEvent(input$clear_codes,{
    x = vals$Data
    x$Include[input$mytable_rows_selected] = ""
    x$Exclude[input$mytable_rows_selected] = ""
    vals$Data = x
  })

  ## remove rows
  observeEvent(input$drop_rows,{
    x = vals$Data
    x$Drop[input$mytable_rows_selected] = TRUE
    vals$Data = x
  })

  ## add label to rows
  observeEvent(input$label_text,{
    vals$label_input = input$label_text
  })

  observeEvent(input$label_codes,{
    x = vals$Data
    x_lab = vals$label_input
    x$Labels[input$mytable_rows_selected] = x_lab
    vals$Data = x
  })

  # create plot data --------------------------------------------------------

  # bar chart data

  local_df = reactive({

    df = hsrdef_barplotdata(x = vals$Data, data = vals$FullData,
                            code_levels = vals$CodeLevels)

    df

  })

  # single bar chart data

  local_df_bar = reactive({

    df2 = hsrdef_donutdata(df = local_df())

    df2

  })

  # create plot outputs -----------------------------------------------------

  # bar chart plot

  output$plot1 = renderPlot({
    if (vals$PlotsActive == TRUE) {
      ggplot(local_df(),aes(y = Code,x = value,fill = name)) +
        geom_bar(stat = "identity", position = "stack",colour = "black") +
        scale_fill_manual(labels = c("Excluded","Maybe","Included"),
                          values = c('#c5ff7f', '#56b63f','#006b09')) +
        labs(x = "",y = "",fill = "") + theme_minimal() +
        theme(axis.text.x = element_blank())
    }
  })

  # donut chart plot

  output$plot2 = renderPlot({
    if (vals$PlotsActive == TRUE) {
      ggplot(local_df_bar(),aes(ymax = ymax,ymin = ymin,xmax = 4,xmin = 3.5,fill = name)) +
        geom_rect(colour = "black") +
        theme_void() +
        coord_flip() +
        scale_fill_manual(labels = c("Excluded","Maybe","Included"),
                          values = c('#c5ff7f', '#56b63f','#006b09')) +
        theme(legend.position = "none")

    }
  })

  # upload saved user codes -------------------------------------------------
  observeEvent(input$uploadCodes,{
    x = vals$Data
    outData = hsrdef_uploaddata(file = input$uploadCodes,old_data = x)

    vals$Data = outData
  }
  )

  # download user selection -------------------------------------------------

  output$downloadData <- downloadHandler(
    filename = function() {
      paste("def-", Sys.Date(), ".csv",sep = "")
    },
    content = function(file) {
      write.csv(vals$Data[,c("Code","Description","Exclude","Include","Labels")],
                file, row.names = FALSE, na = "")
    }
  )

}
