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
  fileName <- tempfile()

  writeLines(
    c("SELECT {{ var }} ",
      "FROM {{ table }};",
      "",
      "SELECT * ",
      "FROM {{ toupper(table) }};"    
      ),
    fileName
  )

  query <- Query(file(fileName))
  query <- Query(query, var ~ someVar, table = "jup")

  expectTrue(query[[1]] == dbtools:::SingleQuery("SELECT someVar \nFROM jup;"))
  expectTrue(query[[2]] == dbtools:::SingleQuery("SELECT * \nFROM JUP;"))
  expectTrue(inherits(query, "SingleQueryList"))

  ## From another file
  fileName <- tempfile()

  writeLines(
    c("SELECT", "{{ value }} AS X;"),
    fileName
  )

  query <- Query(file(fileName), value = 1)
  cred <- Credentials(drv = RSQLite::SQLite, dbname = ":memory:")
  dat <- as.data.frame(sendQuery(cred, query))

  expectTrue(dat$X == 1)
  expectTrue(query == dbtools:::SingleQuery("SELECT\n1 AS X;"))
  
  ## From character
  someQuery <- "SELECT {{ someField }} FROM {{ someTable }};"
  expectTrue(
    Query(someQuery, someField ~ fieldName, someTable ~ tableName) ==
    dbtools:::SingleQuery("SELECT fieldName FROM tableName;")
  )
  
  someQuery <- "SELECT {{ someField }} FROM {{ someTable }} WHERE id = {{ id }};"
  df <- data.frame(id = 1:2)

  query <- Query(someQuery, someField ~ fieldName, someTable ~ tableName, .data = df)

  queryResult <- do.call(
    mapply,
    c(
      list(
        FUN = Query,
        SIMPLIFY = FALSE,
        MoreArgs = list(.x = someQuery, someField ~ fieldName, someTable ~ tableName)),
      df
    ))

  for (i in 1:nrow(df)) expectTrue(query[[i]] == queryResult[[i]])
  
})
