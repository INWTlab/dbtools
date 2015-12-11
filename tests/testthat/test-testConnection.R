test_that("testConnection", {

  workingConnection <- Credentials(drv = RSQLite::SQLite, dbname = ":memory:")
  testthat::expect_true(testConnection(workingConnection, FALSE))

  nonWorkingConnection <- Credentials(drv = RMySQL::MySQL, dbname = "Nirvana")
  testthat::expect_false(testConnection(nonWorkingConnection, FALSE))

  nonWorkingConnectionList <- Credentials(drv = RMySQL::MySQL, dbname = c("Nirvana", "Walhalla"))
  testthat::expect_false(testConnection(nonWorkingConnectionList, FALSE))

  testthat::expect_match(
    testthat::evaluate_promise(
      testConnection(nonWorkingConnectionList, TRUE))$output, "FAILED")

})
