
#' Run shiny app
#'
#' @import shiny
#'
#' @return
#' @export
runDefBuilder <- function(){
  shinyApp(ui = ui, server = server)
}
