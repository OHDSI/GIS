#* @apiTitle My API

#* @get /hello
#* @param name The name to greet
#* @response 200 A greeting message
function(name = "world") {
  list(message = paste("Hello,", name))
}

#* Simple connection test to gaiaDB
#* @param ping Ping the database
#* @get /ping
function() {
  list(
    dbms = paste(connectionDetails$dbms),
    server = paste(connectionDetails$server())
  )
}

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
