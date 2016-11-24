#' SQL Assertions and Formats
#'
#' These functions can be used to format and check the input of queries.
#'
#' @param x (ANY) input
#' @param pattern (character) a regular expression used in \link{grepl}
#' @param negate (logical) if TRUE then an error is thrown if at least one of
#'   the elements in x match pattern. If FALSE all elements in x must match the
#'   pattern.
#' @param assert (function) an assertion fuction
#' @param with (character)
#' 
#' @rdname sqlAssertions
#' @export
#'
#' @examples
#' # Will format and check:
#' sqlInStrs(letters[1:2])
#' sqlInNums(1:2)
#' sqlNames(letters[1:2])
#' sqlNames("a")
#'
#' # Only check:
#' sqlNum(1)
#' sqlNums(1:2)
#' sqlChar("a")
#' sqlChars(letters[1:2])
sqlPattern <- function(x, pattern, negate = TRUE) {

  matchesPattern <- function(x, pattern, negate) {
    reducer <- if (negate) any else all
    res <- reducer(grepl(pattern, x))
    if (negate) !res
    else res
  }

  on_failure(matchesPattern) <- function(call, env) {
    paste0(
      "Sanity check failed. Input contains illegal character.\n",
      env$x, "\nshould ", if(env$negate) "not" else "", "match\n", env$pattern
    )   
  }

  assert_that(matchesPattern(x, pattern, negate))
  x
  
}

#' @rdname sqlAssertions
#' @export
sqlChar <- function(x) {
  stopifnot(length(x) == 1)
  sqlChars(x)
}

#' @rdname sqlAssertions
#' @export
sqlChars <- function(x) {
  punct <- "[\\!\\`\\$\\*\\+\\.\\?\\[\\^\\{\\|\\(\\\\]"
  pattern <- paste0("[ \n\t]|[0-9]|", punct)
  sqlPattern(x, pattern, TRUE)  
}

#' @rdname sqlAssertions
#' @export
sqlNum <- function(x) {
  stopifnot(length(x) == 1)
  sqlNums(x)
}

#' @rdname sqlAssertions
#' @export
sqlNums <- function(x) {
  punct <- "[\\!\\`\\$\\*\\+\\?\\[\\^\\{\\|\\(\\\\]" # allows "."
  pattern <- paste0("[ \n\t]|[a-z]|[A-Z]|", punct)
  sqlPattern(x, pattern, TRUE)
} 

#' @rdname sqlAssertions
#' @export
sqlParan <- function(x, assert = identity) {
  paste0("(", sqlComma(x, assert), ")")
}

#' @rdname sqlAssertions
#' @export
sqlComma <- function(x, assert = identity) {
  paste0(assert(x), collapse = ", ")
}

#' @rdname sqlAssertions
#' @export
sqlEsc <- function(x, assert = identity, with = "`") {
  sqlComma(paste0(with, assert(x), with))
}

#' @rdname sqlAssertions
#' @export
sqlName <- function(x) {
  sqlEsc(x, sqlChar)
}

#' @rdname sqlAssertions
#' @export
sqlNames <- function(x) {
  sqlEsc(x, sqlChars)
}

#' @rdname sqlAssertions
#' @export
sqlInNums <- function(x) {
  sqlParan(x, sqlNums)
}

#' @rdname sqlAssertions
#' @export
sqlInStrs <- function(x) {
  sqlParan(x, function(x) sqlEsc(x, sqlChars, "\""))
}
