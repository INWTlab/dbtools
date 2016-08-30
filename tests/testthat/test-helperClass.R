context("Helper Classes")

test_that("Single Query is good", {

  goodQuery <- "SELECT 1;"
  expect_true(SingleQuery(goodQuery) == goodQuery)

  expect_error(SingleQuery("SELECT 2"))
  expect_error(SingleQuery("SELECT 2; SELECT 1;"))

})


test_that("Query Interface", {

  expectTrue <- function(a) testthat::expect_true(a)
  
  ## From file

  ## From template -- everything is a template

  ## From character

  someQuery <- "SELECT {{ someField }} FROM {{ someTable }};"
  expectTrue(
    Query(someQuery, someField ~ fieldName, someTable ~ tableName) ==
    SingleQuery("SELECT fieldName FROM tableName;")
  )
  
  someQuery <- "SELECT {{ someField }} FROM {{ someTable }} WHERE id = {{ id }};"
  df <- data.frame(id = 1:10)

  Query(someQuery, someField ~ fieldName, someTable ~ tableName, .data = df, .by = "id")
  
})
