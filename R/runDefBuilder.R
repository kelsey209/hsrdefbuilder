
#' Run shiny app
#'
#' @importFrom shiny shinyApp
#'
#' @return run the shiny application
#' @export
runDefBuilder <- function(){
  shinyApp(ui = ui, server = server)
}
