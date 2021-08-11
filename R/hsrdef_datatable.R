
#' Build data table output in server
#'
#' @param vals reactive values to get data from
#'
#' @return
#' @export
#'
#' @examples
hsrdef_datatable <- function(vals){
  DT::renderDataTable({
    x = vals$Data

    # in data is a column created for using definitions across multiple SAS inputs
    if("in_data" %in% colnames(x)){
      x <- x[in_data==1][,!"in_data"]
    }

    x <- x[,c("Code","Description","Include","Exclude","Labels")]

    DT::datatable(x, escape = FALSE, rownames = FALSE, options = list(
      pageLength = 20
    ))
  }
  )
}

