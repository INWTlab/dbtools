#' Copy data to database tables
#'
#' These functions copy data frames to database tables
#'
#' @details Basically, these functions are intended to behave like dbWriteTable.
#' However, there are two notebale exceptions:
#' \enumerate{
#'   \item append is always set to TRUE, i.e. the target database table must
#'   be created or already exist before sendData is called
#'   \item row.names is always set to FALSE, i.e., row.names must be converted
#'   to a variable if you want to keep them
#' }
#' There are four different modes for sending data to the database:
#' \describe{
#'   \item{insert}{INSERT INTO TABLE, i.e. in case of duplicates only the first
#'   entry will be kept}
#'   \item{replace}{REPLACE INTO TABLE, i.e. in case of duplicates only the last
#'   entry will be kept}
#'   \item{truncate}{like dbWriteTable with argument overwrite = TRUE, i.e., the
#'   table is truncated before sending the data}
#'   \item{update}{like insert but falls back to update on duplicate key}
#' }
#'
#' @inheritParams sendQuery
#' @param data A data.frame (or coercible to data.frame)
#' @param table A character string specifying a DBMS table name
#' @param mode One of "insert", "replace", or "truncate"
#' @param ... arguments passed to methods and to \link[dbtools]{reTry}
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

  reTry(..., fun = function(...) {

    on.exit({
      if (exists("con")) {
        dbDisconnect(con)
      }
    })

    con <- do.call(dbConnect, as.list(db))
    sendData(db = con, data = data, table = table, ...)

  })

}

#' @rdname sendData
#' @export
sendData(db ~ DBIConnection, data ~ data.frame, table, ...) %m% {
  dbWriteTable(db, table, data, append = TRUE, row.names = FALSE)
}

#' @rdname sendData
#' @export
sendData(db ~ MySQLConnection, data ~ data.frame, table, ..., mode = "insert") %m% {
  .sendData(db, data, table, ..., mode = mode)
}

#' @rdname sendData
#' @export
sendData(db ~ MariaDBConnection, data ~ data.frame, table, ..., mode = "insert") %m% {
  .sendData(db, data, table, ..., mode = mode)
}

.sendData <- function(db, data, table, ..., mode) {
  stopifnot(is.element(mode, c("insert", "replace", "truncate", "update")))

  on.exit(unlink(path))
  data <- convertToCharacter(data)
  path <- normalizePath(tempfile("dbtools"), "/", FALSE)

  cacheTable(data, path)
  if (mode == "truncate")
    truncateTable(db, table)

  if (mode == "update")
    updateTable(db, path, table, names(data))
  else
    writeTable(db, path, table, names(data), mode)

  TRUE
}

convertToCharacter <- function(data) {
  data[is.na(data)] <- NA # Expression is.na(as.character(NaN)) is false
  data[] <- lapply(data, as.character)
  data
}

truncateTable <- function(db, table) {
  sendQuery(db, SingleQuery(paste0("truncate table ", sqlEsc(table), ";")))
}

cacheTable <- function(data, path) {
  fwrite(data, path, eol = "\n", na = "\\N")
}

writeTable <- function(db, path, table, names, mode) {
  sendQuery(db, sqlLoadData(path, table, names, mode))
}

sqlLoadData <- function(path, table, names, mode) {
  SingleQuery(
    paste0(
      "load data local infile '", path, "' ",
      if (mode == "replace") "replace ",
      "into table ", sqlEsc(table), " ",
      "character set utf8mb4 ",
      "fields terminated by ',' ",
      "optionally enclosed by '\"' ",
      "lines terminated by '\n' ",
      "ignore 1 lines ",
      sqlParan(sqlEsc(names)), ";"
    )
  )
}

updateTable <- function(db, path, table, names) {

  # 1. create temporary table like target table
  createTemporaryTable(db, table)

  # # 2. drop indices - this will speed up the process for larger objects
  # dropIndices(db, addTmpPrefix(table))

  # 3. remove redundant fiels - otherwise we won't be able to do updates on
  # particular fields only without considering defaults
  dropRedundantFields(db, addTmpPrefix(table), names)

  # 4. insert into temporary table
  writeTable(db, path, addTmpPrefix(table), names, mode = "replace")

  # 5. actual update via insert into statement
  updateTargetTable(db, table, names)

}

addTmpPrefix <- function(table) {
  paste0("tmp_", table)
}

createTemporaryTable <- function(db, table) {
  sendQuery(db, sqlCreateTemporaryTable(table))
}

sqlCreateTemporaryTable <- function(table) {
  SingleQuery(
    paste(
      "create temporary table", sqlEsc(addTmpPrefix(table)),
      "like ", sqlEsc(table), ";"
    )
  )
}

# dropIndices <- function(db, table) {
#   sql <- paste0("show index from ", table, ";")
#   indices <- sendQuery(db, SingleQuery(sql))$Key_name
#
#   if (length(indices)) {
#     sendQuery(db, sqlDropIndices(table, indices))
#   }
# }
#
# sqlDropIndices <- function(table, indices) {
#   SingleQuery(
#     paste(
#       "alter table", sqlEsc(table),
#       paste("drop index", unlist(lapply(indices, sqlNames)), collapse = ", "), ";"
#     )
#   )
# }

dropRedundantFields <- function(db, table, names) {
  sql <- paste0("show columns from ", sqlEsc(table), ";")
  allFields <- sendQuery(db, SingleQuery(sql))$Field
  redundantFields <- setdiff(allFields, names)

  if (length(redundantFields)) {
    sendQuery(db, sqlDropRedundantColumns(table, redundantFields))
  }
}

sqlDropRedundantColumns <- function(table, redundantFields) {
  SingleQuery(
    paste(
      "alter table", sqlEsc(table),
      paste("drop", unlist(lapply(redundantFields, sqlNames)), collapse = ", "), ";"
    )
  )
}

updateTargetTable <- function(db, table, names) {
  sendQuery(db, sqlUpdateTargetTable(table, names))
}

sqlUpdateTargetTable <- function(table, names) {
  cols <- unlist(lapply(names, sqlEsc))
  commaSeperatedCols <- sqlComma(cols)
  colsInParan <- sqlParan(cols)
  updateStatement <- sqlComma(sprintf("%s = values(%s)", cols, cols))

  SingleQuery(
    paste(
      "insert into", sqlEsc(table), colsInParan,
      "select", commaSeperatedCols, "from", sqlEsc(addTmpPrefix(table)),
      "on duplicate key update",
      updateStatement, ";"
    )
  )
}
