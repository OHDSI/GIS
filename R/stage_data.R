# STANDARDIZE STAGED DATA
standardize_staged_data <- function(stage_data, spec_table) {
  select_df <- spec_table[spec_table$t_type == "select",]
  result_df <- stage_data[,select_df$t_value] %>% as.data.frame()
  names(result_df) <- select_df$t_name

  hardcode_df <- spec_table[spec_table$t_type == "hardcode",]
  if (nrow(hardcode_df) > 0){
    for(i in 1:nrow(hardcode_df)){
      result_df[hardcode_df$t_name[i]] <- hardcode_df$t_value[i]
    }
  }

  rcode_df <- spec_table[spec_table$t_type == "code",]
  if (nrow(rcode_df) > 0){
    for(i in 1:nrow(rcode_df)){
      result_df[rcode_df$t_name[i]] <- eval(parse(text=rcode_df$t_value[i]))
    }
  }

  return(result_df)
}

# GET STAGING DATA
get_stage_data <- function(rec) {
  # ONLY HANDLES FILES (NO API YET)
  # TODO there has to be a different way to change timeout without changing options
  base_timeout <- getOption('timeout')
  options(timeout = 600)
  if (rec$download_method == "file") {
    if (rec$download_subtype == "zip") {
      tempzip <- paste0(tempfile(), ".zip")
      utils::download.file(rec$download_url, tempzip)
      utils::unzip(tempzip, exdir = tempdir())
      if (rec$download_data_standard == 'shp') {
        return(sf::st_read(file.path(tempdir(), rec$download_filename)))
      } else if (rec$download_data_standard == 'csv') {
        return(utils::read.csv(file.path(tempdir(), rec$download_filename)))
      }

    }
  }
  options(timeout = base_timeout)
}



# CREATE GEOM SPEC TABLE
create_spec_table <- function(json_string_spec) {
  json_spec <- rjson::fromJSON(json_string_spec)
  dplyr::tibble("t_name"=names(json_spec),
                 "t_type"=unlist(lapply(t_name, function(x) json_spec[[x]]$type)),
                 "t_value"=unlist(lapply(t_name, function(x) json_spec[[x]]$value)))
}
