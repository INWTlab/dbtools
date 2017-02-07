context("SQL Assertions")

test_that("sqlPattern", {

  expectError <- function(x) {
    testthat::expect_error(x)
  }

  expectEqual <- function(x, y) {
    testthat::expect_equal(x, y)
  }

  expectError(sqlAssertChar("1"))
  expectError(sqlAssertChar(" "))
  expectError(sqlAssertChar("!"))
  expectError(sqlAssertNum("a1"))
  expectError(sqlAssertNum("a"))
  expectError(sqlAssertAlnum("a1!"))
  expectEqual(sqlAssertAlnum("a1"), "a1")

})

test_that("Formats", {

  expectTrue <- function(x) {
    testthat::expect_true(x)
  }

  expectError <- function(x) {
    testthat::expect_error(x)
  }

  expectTrue(sqlParan(1:2) == "(1, 2)")
  expectTrue(sqlEsc(1) == "`1`")
  expectTrue(sqlEsc(1:2) == "`1`, `2`")
  expectTrue(sqlName("a1") == "`a1`")
  expectError(sqlName("DROP TABLE"))
  expectTrue(sqlNames(letters[1:2]) == "`a`, `b`")
  expectTrue(sqlInChars(letters[1:2]) == "(\"a\", \"b\")")
  expectTrue(sqlInNums(1:2) == "(1, 2)")

})
