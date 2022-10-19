#' Create initial data sets
#'
#' @param input_data_select input data from ui
#' @param load_data use default data or not
#'
#' @import data.table
#' @importFrom tools file_ext
#' @importFrom utils data
#'
#' @return values reactive list with updated data
#' @export
hsrdef_initialdata <- function(input_data_select,load_data = TRUE){

  if (load_data == TRUE) {
  ## upload data
  ext <- file_ext(input_data_select$name)
  validate(need(ext == "csv","Invalid file: please upload a .csv file."))
  data = suppressMessages(fread(file = input_data_select$datapath))

  # check data set has valid columns
  check_columns <- c("_Leaf_","code","DGNS_DESC","all_pc",
                     "all_cnt","leaf_total") %in% colnames(data)

  validate(need(all(check_columns == 1),"Invalid file: column names do not match expected SAS output"))

  } else {
    data <- as.data.table(input_data_select)
  }

  # create data set for table visual
  data_table <- copy(data)
  setorder(data_table,-all_pc,`_Leaf_`,na.last = TRUE)
  setnames(data_table,"code","Code")
  setnames(data_table,"DGNS_DESC","Description")
  data_table <- unique(data_table,by = c("Code","Description"))
  data_table[["ID"]] = seq(1:nrow(data_table))
  data_table <- setalloccol(data_table)
  set(data_table, i = NULL, "Exclude",NA)
  set(data_table, i = NULL, "Include",NA)
  set(data_table, i = NULL, "Labels","")
  set(data_table, i = NULL, "Drop",FALSE)

  # create empty columns for user input
  # data_table[,`:=`(Exclude = NA, Include = NA, Labels = "", Drop = FALSE)]

  check_box_inp <- checkboxInput(inputId = "SUB",
                                 label = NULL)

  check_box_exc <- vapply(X = data_table$ID,
                          FUN = function(x){
                            c1 <- gsub('id="SUB"',paste0('id="SUB" value="',x,'"'),check_box_inp)
                            c2 <- gsub('id="SUB"','name="exc_selected"',c1)
                            return(c2)
                          },
                          FUN.VALUE = vector(mode = "character",length = 1))

  check_box_inc <- vapply(X = data_table$ID,
                          FUN = function(x){
                            c1 <- gsub('id="SUB"',paste0('id="SUB" value="',x,'"'),check_box_inp)
                            c2 <- gsub('id="SUB"','name="inc_selected"',c1)
                            return(c2)
                          },
                          FUN.VALUE = vector(mode = "character",length = 1))

  data_table[["Exclude"]] = check_box_exc
  data_table[["Include"]] = check_box_inc

  # get codes that are top-level leaf counts
  code_levels <- data[all_pc == 100]
  setorder(code_levels,`_Leaf_`)
  code_levels <- unique(code_levels,by = "code")
  code_levels <- as.vector(code_levels[,"code"])

  # output data
  values = list()
  values$Data = data_table
  values$FullData = data
  values$CodeLevels = code_levels

  return(values)
}
