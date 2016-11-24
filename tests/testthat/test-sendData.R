context("sendData-SQLite")

test_that("sendData", {

  # prepare data
  data(mtcars)
  mtcars <- mtcars %>%
    tibble::rownames_to_column("model") %>%
    dplyr::select(model, mpg, cyl, disp, hp, drat, wt, qsec, vs, am, gear, carb)

  # set up connection
  cred <- Credentials(drv = SQLite, dbname = "test.db")

  # create table
  sendQuery(cred, "DROP TABLE IF EXISTS `mtcars`;")

  sendQuery(cred, "CREATE TABLE `mtcars` (
    model TEXT PRIMARY KEY,
    mpg REAL,
    cyl REAL,
    disp REAL,
    hp REAL,
    drat REAL,
    wt REAL,
    qsec REAL,
    vs REAL,
    am REAL,
    gear REAL,
    carb REAL);"
  )

  # send data to database
  sendData(cred, mtcars)

  # retrieve data
  res <- sendQuery(cred, "SELECT * FROM mtcars;")

  # objects should be equal
  expect_identical(res, mtcars %>% tibble::as_data_frame())

  # delete database
  unlink("test.db")
})

test_that("sendQuery can operate on CredentialsList", {

  # prepare data
  data(mtcars)
  mtcars <- mtcars %>%
    tibble::rownames_to_column("model") %>%
    dplyr::select(model, mpg, cyl, disp, hp, drat, wt, qsec, vs, am, gear, carb)

  # set up connection
  cred <- CredentialsList(
    drv = list(SQLite, SQLite),
    dbname = c("db1.db", "db2.db")
  )

  # create table
  sendQuery(cred, "DROP TABLE IF EXISTS `mtcars`;")

  sendQuery(cred, "CREATE TABLE `mtcars` (
    model TEXT PRIMARY KEY,
    mpg REAL,
    cyl REAL,
    disp REAL,
    hp REAL,
    drat REAL,
    wt REAL,
    qsec REAL,
    vs REAL,
    am REAL,
    gear REAL,
    carb REAL);"
  )

  # send data to database
  sendData(cred, mtcars)

  # retrieve data
  res <- sendQuery(cred, "SELECT * FROM mtcars;", simplify = FALSE)

  # there should be two identical instances of mtcars in the result set
  expect_identical(res[[2]][[1]], res[[1]][[1]])
  expect_identical(res[[1]][[1]], mtcars %>% tibble::as_data_frame())

  # delete database
  unlink(c("db1.db", "db2.db"))
})

context("sendQuery-RMySQL")
test_that("sendQuery for RMySQL DB", {
  # Sometimes we get an error if docker has not been startet. Use:
  # sudo service docker.io start
  # check with:
  # sudo service docker.io status

  tmp <- system(
    paste0('docker run --name test-mysql-db -p 127.0.0.1:3306:3306 ',
           '-e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=test -d mysql'),
    intern = TRUE
  )

  Sys.sleep(15) # Takes some time to fire up db:

  # prepare data
  data(mtcars)
  mtcars <- mtcars %>%
    tibble::rownames_to_column("model") %>%
    dplyr::select(model, mpg, cyl, disp, hp, drat, wt, qsec, vs, am, gear, carb)

  cred <- Credentials(
    drv = MySQL,
    user = "root",
    password = "root",
    dbname = "test",
    host = "127.0.0.1",
    port = 3306
  )

  # set up connection
  cred <- Credentials(drv = SQLite, dbname = "test.db")

  # create table
  sendQuery(cred, "DROP TABLE IF EXISTS `mtcars`;")

  sendQuery(cred, "CREATE TABLE `mtcars` (
    model TEXT PRIMARY KEY,
    mpg REAL,
    cyl REAL,
    disp REAL,
    hp REAL,
    drat REAL,
    wt REAL,
    qsec REAL,
    vs REAL,
    am REAL,
    gear REAL,
    carb REAL);"
  )

  # send data to database
  sendData(cred, mtcars)

  # retrieve data
  res <- sendQuery(cred, "SELECT * FROM mtcars;")

  # objects should be equal
  expect_identical(res, mtcars %>% tibble::as_data_frame())

  # End the temp db:
  tmp <- system(
    'docker kill test-mysql-db; docker rm test-mysql-db',
    intern = TRUE
  )

})
