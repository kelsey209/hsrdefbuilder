#' background colour html for user interface
#'
#' @return html style
#' @export
hsrdef_bodystyle <- function(){
  tags$head(tags$style(HTML('
      .content-wrapper {
        background-color: #F1F8E9;
      }
    ')))
}
