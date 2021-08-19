#' User-interface of hsrdefbuilder app
#'
#' @return A shiny user interface
#'
#' @importFrom shinydashboard dashboardPage dashboardHeader dashboardSidebar dashboardBody
#' @export
#'
ui <- function(){

  dashboardPage(dashboardHeader(disable = T),
                dashboardSidebar(hsrdef_sidebar()),
                dashboardBody(hsrdef_bodystyle(),
                              hsrdef_body())
  )

}
