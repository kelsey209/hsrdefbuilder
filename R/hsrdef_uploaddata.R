#' Parse user uploaded file and add labels to data
#'
#' @param file ui from upload handler
#' @param old_data current data table with code table
#'
#' @importFrom tools file_ext
#' @import data.table
#'
#' @return updated data file
#' @export
hsrdef_uploaddata <- function(file,old_data){

  # validate uploaded files
  ext <- file_ext(file$name)
  validate(need(ext == "csv","Invalid file: please upload a .csv file."))
  ui_input = suppressMessages(fread(file$datapath))

  check_cols <- c("Code","Description","ExcludeCode","IncludeCode") %in% colnames(ui_input)
  validate(need(all(check_cols == 1),"Invalid file: check column names"))

  # label current codes if they are in this data set
  ## some times a new uploaded file may contain other codes that do not exist in
  ## this output. we want to create a flag to filter this when creating plots.
  f_data = copy(old_data)
  f_data[,in_data := 1]

  # join full data
  out_data = merge.data.table(f_data[,!c("Labels")],
                              ui_input[,c("Code","Description","IncludeCode","ExcludeCode","Labels")],
                              by = c("Code"),all = TRUE,sort = FALSE)

  # save description from user input data if the code does not exist in this claim set
  out_data[,Description.x := fifelse(is.na(Description.x),Description.y,Description.x)]
  out_data <- out_data[,!c("Description.y")]
  setnames(out_data,"Description.x","Description")

  # update check boxes
  checkbox_exc <- out_data[1,"Exclude"]
  checkbox_exc <- gsub('type="checkbox"',
                       'type="checkbox" checked="checked"',
                       checkbox_exc)
  checkbox_exc <- gsub('checked="checked" checked="checked"',
                       'checked="checked"',
                       checkbox_exc)

  out_data$Exclude[out_data$ExcludeCode == 1] <- checkbox_exc

  checkbox_inc <- out_data[1,"Include"]
  checkbox_inc <- gsub('type="checkbox"',
                       'type="checkbox" checked="checked"',
                       checkbox_inc)
  checkbox_inc <- gsub('checked="checked" checked="checked"',
                       'checked="checked"',
                       checkbox_inc)

  out_data$Include[out_data$IncludeCode == 1] <- checkbox_inc



  # set flag where codes were from previously used definition and not this sample
  out_data[,in_data := fifelse(is.na(in_data),0,in_data)]

  return(out_data)

}
