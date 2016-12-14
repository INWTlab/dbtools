#' Copy data to database tables
#'
#' These functions copy data frames to database tables
#'
#' @details Basically, these functions are intended to behave like dbSendQuery.
#' However, there are two notebale exceptions:
#' \enumerate{
#'   \item append is always set to TRUE, i.e. the target database table must
#'   be created or already exist before sendData is called
#'   \item row.names is always set to FALSE, i.e., row.names must be converted
#'   to a variable if you want to keep them
#' }
#' There are three different modes for sending data to the database:
#' \describe{
#'   \item{insert}{INSERT INTO TABLE, i.e. in case of duplicates only the first
#'   entry will be kept}
#'   \item{replace}{REPLACE INTO TABLE, i.e. in case of duplicates only the last
#'   entry will be kept}
#'   \item{truncate}{like dbWriteTable with argument overwrite = TRUE, i.e., the
#'   table is truncated before sending the data}
#' }
#'
#' @inheritParams sendQuery
#' @param data A data.frame (or coercible to data.frame)
#' @param table A character string specifying a DBMS table name
#' @param mode One of "replace", "append", or "update"
#' @param ... later...
#' @rdname sendData
#' @export
sendData(db, data, table = deparse(substitute(data)), ...) %g% {
  standardGeneric("sendData")
}

#' @rdname sendData
#' @export
sendData(db ~ CredentialsList, data ~ data.frame, table, ..., applyFun = lapply) %m% {
  applyFun(db, sendData, data = data, table = table, ...)
}

#' @rdname sendData
#' @export
sendData(db ~ Credentials, data ~ data.frame, table, ...) %m% {

  con <- do.call(dbConnect, as.list(db))

  on.exit ({
    if (exists("con")) {
      dbDisconnect(con)
    }
  })

  sendData (
    db = con,
    data = data,
    table = table,
    ...
  )
}

#' @rdname sendData
#' @export
sendData(db ~ DBIConnection, data ~ data.frame, table, ...) %m% {
  dbWriteTable(db, table, data, append = TRUE, row.names = FALSE)
}

#' @rdname sendData
#' @export
sendData(db ~ MySQLConnection, data ~ data.frame, table, ..., mode = "insert") %m% {

  path <- normalizePath(tempfile("dbtools"), "/", FALSE)
  on.exit(unlink(path))

  cacheTable(data, path)
  if (mode == "truncate")
    truncateTable(db, table)
  writeTable(db, path, table, mode)
}

truncateTable <- function(db, table) {
  sendQuery(db, SingleQuery(paste0("TRUNCATE TABLE ", table, ";")))
}

cacheTable <- function(data, path) {
  write_delim(data, path, delim = ",", na = "\\N")
}

writeTable <- function(db, path, table, mode) {
  sendQuery(db, sqlLoadData(path, table, mode))
}

sqlLoadData <- function(path, table, mode) {
  SingleQuery (
    paste0 (
      "LOAD DATA LOCAL INFILE '",
      path,
      "' ",
      if (mode == "replace")
        "REPLACE ",
      "INTO TABLE `",
      table,
      "` ",
      "CHARACTER SET UTF8 ",
      "FIELDS TERMINATED BY ',' ",
      "OPTIONALLY ENCLOSED BY '\"' ",
      "LINES TERMINATED BY '\n' ",
      "IGNORE 1 LINES;"
    )
  )
}
