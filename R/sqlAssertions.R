#' SQL Assertions and Formats
#'
#' These functions can be used to format and check the input of queries.
#'
#' @param x (ANY) input
#' @param pattern (character) a regular expression used in \link{grepl}
#' @param negate (logical) if TRUE then an error is thrown if at least one of
#'   the elements in x match pattern. If FALSE all elements in x must match the
#'   pattern.
#' @param assert (function) an assertion function
#' @param with (character)
#' 
#' @rdname sqlAssertions
#' @export
#'
#' @examples
#' # Will format and check:
#' sqlInChars(letters[1:2])
#' sqlInNums(1:2)
#' sqlNames(letters[1:2])
#' sqlName("a")
#'
#' # Only check:
#' sqlAssertNum(1)
#' sqlAssertNums(1:2)
#' sqlAssertChar("a")
#' sqlAssertChars(letters[1:2])
sqlAssertPattern <- function(x, pattern, negate = TRUE) {

  matchesPattern <- function(x, pattern, negate) {
    reducer <- if (negate) any else all
    res <- reducer(grepl(pattern, x))
    if (negate) !res
    else res
  }

  on_failure(matchesPattern) <- function(call, env) {
    paste0(
      "Plausibility check failed. Input contains illegal character.\n",
      env$x, "\nshould ", if(env$negate) "not " else "", "match\n", env$pattern
    )   
  }

  assert_that(matchesPattern(x, pattern, negate))
  x
  
}

#' @rdname sqlAssertions
#' @export
sqlAssertChar <- function(x) {
  stopifnot(length(x) == 1)
  sqlAssertChars(x)
}

#' @rdname sqlAssertions
#' @export
sqlAssertChars <- function(x) {
  punct <- "[\\!\\`\\$\\*\\+\\.\\?\\[\\^\\{\\|\\(\\\\]"
  pattern <- paste0("[ \n\t]|[0-9]|", punct)
  sqlAssertPattern(x, pattern, TRUE)  
}

#' @rdname sqlAssertions
#' @export
sqlAssertNum <- function(x) {
  stopifnot(length(x) == 1)
  sqlAssertNums(x)
}

#' @rdname sqlAssertions
#' @export
sqlAssertNums <- function(x) {
  punct <- "[\\!\\`\\$\\*\\+\\?\\[\\^\\{\\|\\(\\\\]" # allows "."
  pattern <- paste0("[ \n\t]|[a-z]|[A-Z]|", punct)
  sqlAssertPattern(x, pattern, TRUE)
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
  sqlEsc(x, sqlAssertChar)
}

#' @rdname sqlAssertions
#' @export
sqlNames <- function(x) {
  sqlEsc(x, sqlAssertChars)
}

#' @rdname sqlAssertions
#' @export
sqlInNums <- function(x) {
  sqlParan(x, sqlAssertNums)
}

#' @rdname sqlAssertions
#' @export
sqlInChars <- function(x) {
  sqlParan(x, function(x) sqlEsc(x, sqlAssertChars, "\""))
}
