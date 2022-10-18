#' Server function for hsrdefbuilder app
#'
#' @param input ui input
#' @param output plot and table outputs
#' @param session shiny server session
#'
#' @importFrom ggplot2 ggplot aes geom_bar scale_fill_manual labs theme_minimal theme geom_rect theme_void coord_flip element_blank
#' @importFrom DT renderDataTable datatable
#' @importFrom utils head write.csv data
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

  # use default selection ---------------------------------------------------
  observeEvent(input$load_example, {
    data(exampledata)
    outData = hsrdef_initialdata(input_data_select = exampledata,load_data = FALSE)
    vals$Data = outData$Data
    vals$FullData = outData$FullData
    vals$CodeLevels = outData$CodeLevels
    vals$PlotsActive = TRUE
    vals$ExcludeCodes = vector(mode = "character")
    vals$IncludeCodes = vector(mode = "character")
  })


  # read in input data and create data frames ------------------------------

  observeEvent(input$data_select, {
    outData = hsrdef_initialdata(input_data_select = input$data_select)
    vals$Data = outData$Data
    vals$FullData = outData$FullData
    vals$CodeLevels = outData$CodeLevels
    vals$PlotsActive = TRUE
    vals$ExcludeCodes = vector(mode = "character")
    vals$IncludeCodes = vector(mode = "character")
  })

  # create data table -------------------------------------------------------

  output$mytable <- DT::renderDataTable({
    x <- hsrdef_datatable(vals$Data)
    DT::datatable(x,
                  escape = FALSE,
                  rownames = FALSE,
                  options = list(pageLength = 20),
                  selection = "multiple")
  },
  server = FALSE)

  # # apply user criteria -----------------------------------------------------

  ## excluded codes
  observeEvent(input$checked_exc_rows,{
    x = vals$ExcludeCodes
    x = unique(c(x,input$checked_exc_rows))
    vals$ExcludeCodes = x
  })

  ## un select excluded codes
  observeEvent(input$unchecked_exc_rows,{
    x = vals$ExcludeCodes
    x = x[!x %in% input$unchecked_exc_rows]
    vals$ExcludeCodes = x
  })

  ## excluded codes -- button
  observeEvent(input$exclude_codes,{
    x = vals$Data
    y = vals$ExcludeCodes
    z = vals$IncludeCodes
    x$Exclude[input$mytable_rows_selected] = gsub(pattern = 'type="checkbox"',
                                                  replacement = 'type="checkbox" checked="checked"',
                                                  x = x$Exclude[input$mytable_rows_selected])
    x$Include[input$mytable_rows_selected] = gsub(pattern = 'checked="checked"',
                                                  replacement = '',
                                                  x = x$Include[input$mytable_rows_selected])
    y = unique(c(y,x$Code[input$mytable_rows_selected]))
    z = z[!z %in% x$Code[input$mytable_rows_selected]]
    vals$Data = x
    vals$ExcludeCodes = y
    vals$IncludeCodes = z
  })

  ## included codes
  observeEvent(input$checked_inc_rows,{
    x = vals$IncludeCodes
    x = unique(c(x,input$checked_inc_rows))
    vals$IncludeCodes = x
  })

  ## un select included codes
  observeEvent(input$unchecked_inc_rows,{
    x = vals$IncludeCodes
    x = x[!x %in% input$unchecked_inc_rows]
    vals$IncludeCodes = x
  })

  ## include codes -- button
  observeEvent(input$include_codes,{
    x = vals$Data
    y = vals$IncludeCodes
    z = vals$ExcludeCodes
    x$Include[input$mytable_rows_selected] = gsub(pattern = 'type="checkbox"',
                                                  replacement = 'type="checkbox" checked="checked"',
                                                  x = x$Include[input$mytable_rows_selected])
    x$Exclude[input$mytable_rows_selected] = gsub(pattern = 'checked="checked"',
                                                  replacement = '',
                                                  x = x$Exclude[input$mytable_rows_selected])
    y = unique(c(y,x$Code[input$mytable_rows_selected]))
    z = z[!z %in% x$Code[input$mytable_rows_selected]]
    vals$Data = x
    vals$IncludeCodes = y
    vals$ExcludeCodes = z
  })

  ## remove criteria
  observeEvent(input$clear_codes,{

    vals$ExcludeCodes = vector(mode = "character")
    vals$IncludeCodes = vector(mode = "character")

  })

  ## remove rows
  observeEvent(input$drop_rows,{
    x = vals$Data
    x$Drop[input$mytable_rows_selected] = TRUE
    vals$Data = x
  })

  observeEvent(input$label_codes,{
    x = vals$Data
    x_lab = input$label_text
    x_codes = x$Code[input$mytable_rows_selected]
    x$Labels[x$Code %in% x_codes] = x_lab
    vals$Data = x
  })

  # create plot data --------------------------------------------------------

  # bar chart data

  local_df = reactive({

    df = hsrdef_barplotdata(x = vals$Data,
                            data = vals$FullData,
                            code_levels = vals$CodeLevels,
                            include_codes = vals$IncludeCodes,
                            exclude_codes = vals$ExcludeCodes)

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
    vals$ExcludeCodes = outData$Code[outData$ExcludeCode == 1]
    vals$IncludeCodes = outData$Code[outData$IncludeCode == 1]
  }
  )

  # download user selection -------------------------------------------------

  output$downloadData <- downloadHandler(
    filename = function() {
      paste("def-", Sys.Date(), ".csv",sep = "")
    },
    content = function(file) {
      x = copy(vals$Data)
      x[,ExcludeCode := fifelse(x$Code %in% vals$ExcludeCodes,1,0)]
      x[,IncludeCode := fifelse(x$Code %in% vals$IncludeCodes,1,0)]
      write.csv(x[,c("Code","Description","ExcludeCode","IncludeCode","Labels")],
                file, row.names = FALSE, na = "")
    }
  )

}
