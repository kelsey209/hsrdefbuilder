#' Create initial data sets
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
  validate(need(ext == "csv","Invalid file: please upload a .csv file."))
  data = suppressMessages(fread(file = input_data_select$datapath))

  # check data set has valid columns
  check_columns <- c("_Leaf_","code","DGNS_DESC","all_pc",
                     "all_cnt","leaf_total") %in% colnames(data)

  validate(need(all(check_columns == 1),"Invalid file: column names do not match expected SAS output"))

  # create data set for table visual
  data_table <- data
  setorder(data_table,-all_pc,`_Leaf_`,na.last = TRUE)
  setnames(data_table,"code","Code")
  setnames(data_table,"DGNS_DESC","Description")
  data_table <- unique(data_table,by = c("Code","Description"))

  # create empty columns for user input
  data_table[,`:=`(Exclude = NA, Include = NA, Labels = "", Drop = FALSE)]

  data_table[["Exclude"]] = glue::glue('<input type="checkbox" name="exc_selected" {data_table$Exclude} value="{1:nrow(data_table)}"><br>')
  data_table[["Include"]] = glue::glue('<input type="checkbox" name="inc_selected" {data_table$Include} value="{1:nrow(data_table)}"><br>')
  data_table[["ID"]] = seq(1:nrow(data_table))

  # get codes that are top-level leaf counts
  code_levels <- data[all_pc == 100]
  setorder(code_levels,`_Leaf_`)
  code_levels <- unique(code_levels,by = "Code")
  code_levels <- as.vector(code_levels[,"Code"])

  # output data
  values = list()
  values$Data = data_table
  values$FullData = data
  values$CodeLevels = code_levels

  return(values)
}
