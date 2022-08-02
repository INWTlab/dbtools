deparseURL <- function(url) {
    driver <- "[^[:space:]]+"
    user <- "[^:[:space:]]+"
    pw <- "[^[:space:]]+"
    host <- "[^:/[:space:]]+"
    port <- "[:digit:]+"
    db <- "[[:alnum:]\\_]+"
    regex <- sprintf(
        "(%s)://(%s)?:?(%s)?@(%s):?(%s)?/?(%s)?",
        driver, user, pw, host, port, db
    )
    matches <- stringi::stri_match(url, regex = regex)
    if (all(is.na(matches))) {
        regex <- sprintf(
            "(%s)://(%s):?(%s)?/?(%s)?",
            driver, host, port, db
        )
        matches <- stringi::stri_match(url, regex = regex)
        matches <- c(matches[1:2], NA_character_, NA_character_, matches[3:5])
    }
    matches <- as.list(matches)
    names(matches) <- c(
        "url", "driver", "username", "password", "host", "port", "database"
    )
    matches
}

mapURLToDriverArguments <- function(driver, arguments, ...) {
    UseMethod("mapURLToDriverArguments")
}

mapURLToDriverArguments.default <- function(driver, arguments, ...) {
    arguments$url <- NULL
    arguments[!is.na(unlist(arguments))]
}

mapURLToDriverArguments.SQLiteDriver <- function(driver, arguments, ...) {
    dbname <- arguments$host
    if (dbname == "memory") dbname <- ":memory:"
    list(dbname = dbname)
}

mapURLToDriverArguments.MySQLDriver <- function(driver, arguments, ...) {
    args <- list(
        user = arguments$username,
        password = arguments$password,
        host = arguments$host,
        port = as.integer(arguments$port),
        dbname = arguments$database
    )
    args[!is.na(args)]
}

mapURLToDriverArguments.MariaDBDriver <- function(driver, arguments, ...) {
    mapURLToDriverArguments.MySQLDriver(driver, arguments, ...)
}

mapURLToDriverArguments.ClickhouseDriver <- function(driver, arguments, ...) {
    args <- list(
        user = arguments$username,
        password = arguments$password,
        host = arguments$host,
        port = as.integer(arguments$port),
        db = arguments$database
    )
    args[!is.na(args)]
}
