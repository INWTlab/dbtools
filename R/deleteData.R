deleteData <- function(db, name, value) {
  tblInfo <- sendQuery(db, sprintf("DESCRIBE %s;", name))
  primary <- tblInfo$Field[tblInfo$Key == "PRI"]

  stopifnot(length(primary) == 1)

  values <- value[[primary]]

  sendQuery (
    db,
    sprintf (
      "DELETE FROM %s WHERE %s IN (%s);",
      name, primary, paste(values, collapse = ", ")
    )
  )

}
