#' background colour html for user interface
#'
#' @return
#' @export
#'
#' @examples
hsrdef_bodystyle <- function(){
  tags$head(tags$style(HTML('
      .content-wrapper {
        background-color: #F1F8E9;
      }
    ')))
}
