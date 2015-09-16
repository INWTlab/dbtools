context("Helper Classes")

test_that("Single Query is good", {

  goodQuery <- "SELECT 1;"
  expect_true(SingleQuery(goodQuery) == goodQuery)

  expect_error(SingleQuery("SELECT 2"))
  expect_error(SingleQuery("SELECT 2; SELECT 1;"))

})
