#' Function for reactive data update before plotting
#'
#' @param x the original SAS upload data
#' @param data the modified data with Include and Exclude labels
#' @param code_levels the code levels to include in the plots
#' @param include_codes the codes the definition must include
#' @param exclude_codes the codes the definition must not include
#'
#' @import data.table
#'
#' @return bar plot data
#' @export
hsrdef_barplotdata <- function(x,data,code_levels,
                               include_codes,
                               exclude_codes){

  if ("in_data" %in% colnames(x)) {
    x <- x[in_data == 1]
  }

  data <- data.table::merge.data.table(data,x[,c("Code")],
                           by.x = "Code", by.y = "Code")

  # include codes: where user input == I ------------------------------------
  include_sub <- data[Code %in% include_codes]
  include_sub[,`:=`(all_cnt_low = fifelse(is.na(all_cnt),1,all_cnt),
                    all_cnt_up = fifelse(is.na(all_cnt),10,all_cnt))]

  include_sub[,`:=`(Include_min = sum(all_cnt_low),
                    Include_max = sum(all_cnt_up)),
              by = "_Leaf_"]

  include_sub <- unique(include_sub[,c("_Leaf_","Include_min","Include_max")])

  n_include = nrow(include_sub)

  # exclude codes: where user input == E ------------------------------------

  exclude_sub <- data[Code %in% exclude_codes]
  exclude_sub[,`:=`(all_cnt_low = fifelse(is.na(all_cnt),1,all_cnt),
                   all_cnt_up = fifelse(is.na(all_cnt),10,all_cnt))]

  # the minimum to exclude is the maximum across the all count lowest values,
  # since we are assuming this overlaps with the other claim counts in the leaf
  exclude_sub[,`:=`(Exclude_min = suppressWarnings(max(all_cnt_low)),
                    Exclude_max = sum(all_cnt_up)),
              by = "_Leaf_"]

  exclude_sub <- unique(exclude_sub[,c("_Leaf_","Exclude_min","Exclude_max")])

  # create output data set  -------------------------------------------------

  # select codes where all_pc is maximum
  df <- setorder(setDT(data[!is.na(all_pc) & `_Leaf_` != 0]),
                 `_Leaf_`,-all_pc,na.last = TRUE)[,indx := seq_len(.N),by = "_Leaf_"][indx == 1]

  # add included/excluded values
  df <- merge.data.table(df,include_sub,by = "_Leaf_",all.x = TRUE)
  df <- merge.data.table(df,exclude_sub,by = "_Leaf_",all.x = TRUE)

  # replace values with 0
  cols <- c("Include_min","Include_max","Exclude_min","Exclude_max")
  for (j in cols) set(df, j = j, value = fifelse(is.na(df[[j]]),0,df[[j]]))

  # control for overlap in Leaf counts for Inclusion/Exclusion
  df[,Exclude_max := apply(.SD, 1, min), .SDcols = c("Exclude_max","leaf_total")]
  df[,Include_max := apply(.SD, 1, min), .SDcols = c("Include_max","leaf_total")]

  # include everything if there is no user Inclusions
  df[,`:=`(Include_min = fifelse(rep(n_include,nrow(df)) == 0,leaf_total,Include_min),
           Include_max = fifelse(rep(n_include,nrow(df)) == 0,leaf_total,Include_max))]

  # count inclusions
  df[,P1 := Include_min]
  df[,G1 := Include_max - P1]
  df[,E1 := leaf_total - G1 - P1]

  # count exclusions
  df[,P2 := leaf_total - Exclude_max]
  df[,G2 := leaf_total - Exclude_min - P2]
  df[,E3 := leaf_total - G2 - P2]

  # apply final counts: intersections of these criteria
  df[,Potential := apply(.SD, 1, min), .SDcols = c("P1","P2")]
  df[,DefExclude := apply(.SD, 1, max), .SDcols = c("E1","E3")]
  df[,GreyZone := leaf_total - Potential - DefExclude]

  df <- df[,c("_Leaf_","Code","Potential","GreyZone","DefExclude")]

  df <- melt(df,id.vars = c("_Leaf_","Code"),measure.vars = c("Potential","GreyZone","DefExclude"),variable.name = "name")

  df[,Code := factor(Code,levels = rev(unlist(code_levels)))]

  df[,name := factor(name,levels = c("DefExclude","GreyZone","Potential"))]

  # add any claim counts for leaf zero, where no important features were included
  # only if this is not a masked count
  if (0 %in% data$`_Leaf_` && !is.na(data$leaf_total[data$`_Leaf_` == 0][1])) {
    df <- rbindlist(list(df,
                         data.table(`_Leaf_` = 0,
                                    Code = "-",
                                    name = "GreyZone",
                                    value = data$leaf_total[data$`_Leaf_` == 0][1])))

    df[,Code := factor(Code,levels = rev(c("-",unlist(code_levels))))]
  }

  # remove missing code level counts -- fail safe
  df <- df[is.na(Code) == FALSE]

  return(df)

}
