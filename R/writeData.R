writeData(db, name, value, replace, ...) %g% {
  standardGeneric("writeData")
}

writeData(db ~ CredentialsList, name ~ character, value ~ data.frame | list, replace ~ logical, ..., applyFun = lapply) %m% {
  applyFun(db, writeData, name = name, value = value, replace = replace, ..., simplify = FALSE)
}

writeData(db ~ Credentials, name ~ character, value ~ data.frame, replace ~ logical, ...) %m% {
  writeData(db = db, name = as.list(name), value = list(value), replace = replace, ...)
}

writeData(db ~ Credentials, name ~ character, value ~ list, replace ~ logical, ...) %m% {
  writeData(db = db, name = as.list(name), value = value, replace = replace, ...)
}

writeData(db ~ Credentials, name ~ list, value ~ list, replace ~ logical, ...) %m% {
  on.exit({
    if (exists("con")) {
      dbDisconnect(con)
    }
  })

  con <- do.call(dbConnect, as.list(db))
  reTry(
    function(...) mapply (
      writeData,
      name = name,
      value = value,
      replace = replace,
      MoreArgs = list(db = con),
      SIMPLIFY = FALSE,
      ...
    ),
    ...
  )

  TRUE
}

writeData(db ~ DBIConnection, name ~ character, value ~ data.frame, replace ~ logical, ...) %m% {
  if (replace) deleteData(db, name, value)
  dbWriteTable(db, name, value, row.names = FALSE, append = TRUE)
}
