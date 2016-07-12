#' Copy data to database tables
#'
#' This functions copies data frames to database tables
#'
#' @param db one in:
#'   \cr (\link{Credentials}) the credentials to get a connection to a database.
#'   \cr (DBIConnection) \link[DBI]{DBIConnection-class}
#' @param name (character, length >= 1) data base table name(s)
#' @param value one in:
#'   \cr (\link[base]{data.frame})
#'   \cr (\link[base]{list}) of data.frames
#' @inheritParams sendQuery
#'
#' @rdname sendData
#' @export
sendData(db, name, value, ...) %g% {
  standardGeneric("sendData")
}

#' @rdname sendData
#' @export
sendData(db ~ CredentialsList, name ~ character, value ~ data.frame | list, ..., applyFun = lapply) %m% {
  applyFun(db, sendData, name = name, value = value, ..., simplify = FALSE)
}

#' @rdname sendData
#' @export
sendData(db ~ Credentials, name ~ character, value ~ data.frame, ...) %m% {
  sendData(db = db, name = as.list(name), value = list(value), ...)
}

#' @rdname sendData
#' @export
sendData(db ~ Credentials, name ~ character, value ~ list, ...) %m% {
  sendData(db = db, name = as.list(name), value = value, ...)
}

#' @rdname sendData
#' @export
sendData(db ~ Credentials, name ~ list, value ~ list, ...) %m% {
  on.exit({
    if (exists("con")) {
      dbDisconnect(con)
    }
  })

  con <- do.call(dbConnect, as.list(db))
  reTry(
    function(...) mapply (
      sendData,
      name = name,
      value = value,
      MoreArgs = list(db = con),
      SIMPLIFY = FALSE,
      ...
    ),
    ...
  )

  TRUE
}

#' @rdname sendData
#' @export
sendData(db ~ DBIConnection, name ~ character, value ~ data.frame, ...) %m% {
  dbWriteTable(db, name, value, row.names = FALSE, append = TRUE)
}
