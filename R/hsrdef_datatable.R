
#' Build data table output in server
#'
#' @param x reactive values to get data from
#'
#' @import data.table
#'
#' @return data table to print
#' @export
hsrdef_datatable <- function(x){

  # in data is a column created for using definitions across multiple SAS inputs
  if ("in_data" %in% colnames(x)) {
    x <- x[in_data == 1][,!"in_data"]
  }

  # if data set has been loaded
  if ("Drop" %in% colnames(x)) {
    x <- x[Drop == FALSE,]
  }

  x <- x[,c("Code","Description","Include","Exclude","Labels")]

  return(x)
}

