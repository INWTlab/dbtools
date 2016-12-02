context("SQL Assertions")

test_that("sqlPattern", {

  expectError <- function(x) {
    testthat::expect_error(x)
  }

  expectError(
    sqlPattern("1 2", "[ ]", TRUE)
  )

  expectError(
    sqlPattern("12", "[ ]", FALSE)
  )

  expectError(sqlChar("1"))
  expectError(sqlChar(" "))
  expectError(sqlChar("!"))
  expectError(sqlNum("a1"))
  expectError(sqlNum("a"))
  
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
  expectTrue(sqlName("a") == "`a`")
  expectError(sqlName("DROP TABLE"))
  expectTrue(sqlNames(letters[1:2]) == "`a`, `b`")
  expectTrue(sqlInChars(letters[1:2]) == "(\"a\", \"b\")")
  expectTrue(sqlInNums(1:2) == "(1, 2)")  
    
})
