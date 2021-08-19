#' Create inital data sets
#'
#' @param input_data_select input data from ui
#' @param values vals list from server
#'
#' @import data.table
#' @importFrom tools file_ext
#'
#' @return values reactive list with updated data
#' @export
hsrdef_initialdata <- function(input_data_select){

  ## upload data
  ext <- file_ext(input_data_select$name)
  switch(ext,
         csv = {data = suppressMessages(fread(file = input_data_select$datapath))},
         validate("Invalid file: please upload a .csv file."))

  # check data set has valid columns
  check_columns <- colnames(data) == c("_Leaf_","code","DGNS_DESC","all_pc","prnc_pc",
                                       "all_cnt","prnc_cnt","leaf_total")
  switch(any(check_columns < 1),
         "TRUE" = {validate("Invalid file: column names do not match expected SAS output")})

  # create data set based on leaf/group totals
  data_waffle <- unique(data,by=c("_Leaf_","leaf_total"))
  data_waffle[,leaf_pc:=round(leaf_total/sum(leaf_total,na.rm=T)*100)]
  data_waffle <- data_waffle[,c("_Leaf_","leaf_pc")]
  data_waffle[,leaf_pc:=fifelse(is.na(leaf_pc),0,leaf_pc)]

  # create data set for table visual
  data_table <- merge.data.table(data,data_waffle,by="_Leaf_",all.x=TRUE)
  setorder(data_table,-all_pc,`_Leaf_`,na.last = TRUE)
  setnames(data_table,"code","Code")
  setnames(data_table,"DGNS_DESC","Description")
  data_table <- unique(data_table,by=c("Code","Description"))

  # create empty columns for user input
  data_table[,`:=`(Exclude = "",Include = "",Labels="")]
  data[,`:=`(Exclude = "",Include = "")]

  # get codes that are top-level leaf counts
  code_levels <- data[all_pc == 100]
  setorder(code_levels,-leaf_total)
  code_levels <- unique(code_levels,by="code")
  code_levels <- as.vector(code_levels[,"code"])

  # output data
  values = list()
  values$Data = data_table
  values$FullData = data
  values$CodeLevels = code_levels

  return(values)
}
