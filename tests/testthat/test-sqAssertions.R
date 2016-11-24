context("SQL Assertions")

test_that("sqPattern", {

  expectError <- function(x) {
    testthat::expect_error(x)
  }

  expectError(
    sqPattern("1 2", "[ ]", TRUE)
  )

  expectError(
    sqPattern("12", "[ ]", FALSE)
  )

  expectError(sqChar("1"))
  expectError(sqChar(" "))
  expectError(sqChar("!"))
  expectError(sqNum("a1"))
  expectError(sqNum("a"))
  
})

test_that("Formats", {

  expectTrue <- function(x) {
    testthat::expect_true(x)
  }

  expectError <- function(x) {
    testthat::expect_error(x)
  }

  expectTrue(sqParan(1:2) == "(1, 2)")
  expectTrue(sqEsc(1) == "`1`")
  expectTrue(sqEsc(1:2) == "`1`, `2`")
  expectTrue(sqName("a") == "`a`")
  expectError(sqName("DROP TABLE"))
  expectTrue(sqNames(letters[1:2]) == "`a`, `b`")
  expectTrue(sqInStrs(letters[1:2]) == "(\"a\", \"b\")")
  expectTrue(sqInNums(1:2) == "(1, 2)")  
    
})



