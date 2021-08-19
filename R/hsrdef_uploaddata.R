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
  switch(ext,
         csv = {ui_input = suppressMessages(fread(file$datapath))},
         validate("Invalid file; please upload a .csv file"))

  check_cols <- ifelse(all(c("Code","Exclude","Include") %in% colnames(ui_input)),
                       "Yes","No")
  switch(check_cols,
         No = {
           validate("Invalid file: check column names")
         }
  )

  # label current codes if they are in this data set
  ## some times a new uploaded file may contain other codes that do not exist in
  ## this output. we want to create a flag to filter this when creating plots.
  old_data[,in_data:=1]

  # join full data
  out_data = merge.data.table(old_data[,!c("Include","Exclude","Labels")],
                              ui_input[,c("Code","Include","Exclude","Labels")],
                              by = "Code",all = TRUE,sort = FALSE)

  return(out_data)

}
