#' Build reactive data set for donut chart or single bar chart
#'
#' @param df data set returned from bar chart hsrdef_table
#'
#' @import data.table
#'
#' @return data set to use in second bar chart
#' @export
hsrdef_donutdata <- function(df){

  df2 <- copy(df)
  df2 <- df2[,.(value = sum(value,na.rm = TRUE)),by = "name"]
  df2[,value := value/sum(value,na.rm = TRUE)]
  df2[,ymax := cumsum(value)]

  df2[,ymin := c(0,unlist(head(df2[,"ymax"],n = -1)))]

  return(df2)

}
