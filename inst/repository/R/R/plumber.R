#* Load the variable from the variable_source
#* @param variable_id The variable to load
#* @get /load
function(variable_id=-1){
  if (variable_id > 0) {
    res <- capture.output(
      gaiaCore::loadVariable(connectionDetails,variable_id),
      type='message'
    )
  } else {
    res <- 'You must pass a variable_id'
  }
  list(res)
}