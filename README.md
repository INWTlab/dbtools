[![Travis-CI Build Status](https://travis-ci.org/INWT/dbtools.svg?branch=master)](https://travis-ci.org/INWT/dbtools)

This package abstracts typical patterns used when connecting to and communicating with databases in R. It aims to provide very few, simple and reliable functions for sending queries and data to databases.

Installation
------------

``` r
devtools::install_github("INWT/dbtools")
```

We will start with a simple example showing how to use `dbtools` to send queries and data to a database. The example will introduce the main parts of the package, namely the *Credentials* class as well as both `sendQuery` and `sendData`.

Introductory example
--------------------

In this example we show how to connect to a database, how to communicate with the database, how to set up a database table, and finally how to send and retrieve data.

To begin with, we have to define an object of class *Credentials* which will store all necessary information to connect to a database. The driver is mandatory, all other arguments depend on the specific back-end.

``` r
library("dbtools")
```

    ## Loading required package: aoos

``` r
cred <- Credentials(drv = RSQLite::SQLite, dbname = "example.db")
```

Opposed to the functions available from DBI, functions from `dbtools` need a *Credentials* instance as argument that takes care of connecting to the database, communicating with the database and closing the connection.

Now, let's check whether we can actually access the database example.db.

``` r
testConnection(cred)
```

    ## INFO [2018-03-08 11:23:02] example.db OK

``` r
cred
```

    ## An object of class "Credentials"
    ## drv:SQLiteDriver
    ## dbname: example.db

For the remainder of this example, we make use of the USArrests dataset. Unfortunately, the data contains some information in its row names, namely the respective state. Since `dbtools` does not support row names, we have to convert them to a variable.

``` r
data(USArrests, envir = environment())
USArrests$State <- row.names(USArrests)
USArrests <- USArrests[c(length(USArrests), 1:(length(USArrests) - 1))]
row.names(USArrests) <- NULL
USArrests
```

Next, we will create the database table by sending a `CREATE TABLE` query to the database.

``` r
sendQuery(
  cred, 
  "CREATE TABLE `USArrests` (
  State TEXT PRIMARY KEY, 
  Murder INTEGER,
  Assault REAL,
  UrbanPop REAL,
  Rape INTEGER);"
)
```

Now, we can write the USArrests data to the USArrests database table by using the `sendData` function.

``` r
sendData(cred, USArrests)
```

If we want to read data from the database, we can do this by using `sendQuery`, the same function we used for creating the database table.

``` r
dat <- sendQuery(cred, "SELECT * FROM `USArrests`;")
dat
```

Now we will dig a bit deeper into the functionality of `dbtools`.

sendQuery
---------

Basically, you already know how to use `sendQuery`. In our introductory example we used it to create a database table and to query some data.

In your normal work-flow you will sometimes want to split up a complex query into more tangible chunks. The approach we take here is to allow for a vector of queries as argument. The result of these queries have to be *row-bindable*. To make an example lets say we want to query each state separately:

``` r
queryFun <- function(state) {
  paste0("SELECT * FROM USArrests WHERE State = '", state, "';")
}

sendQuery(cred, queryFun(dat$State))
```

    ##             State Murder Assault UrbanPop Rape
    ##  1:       Alabama   13.2     236       58 21.2
    ##  2:        Alaska   10.0     263       48 44.5
    ##  3:       Arizona    8.1     294       80 31.0
    ##  4:      Arkansas    8.8     190       50 19.5
    ##  5:    California    9.0     276       91 40.6
    ## ---                                           
    ## 46:      Virginia    8.5     156       63 20.7
    ## 47:    Washington    4.0     145       73 26.2
    ## 48: West Virginia    5.7      81       39  9.3
    ## 49:     Wisconsin    2.6      53       66 10.8
    ## 50:       Wyoming    6.8     161       60 15.6

In such a case `sendQuery` will perform all queries on one connection. A different approach is to fetch the results of the original query in chunks, which we do not support yet.

sendData
--------

As with `sendQuery`, you basically already know how to use `sendData`. In the introductory example we used it to send the USArrests data to the USArrests database table.

When using `sendData` you might be interesting in how to handle possible primary key violations. By default, `sendData` will keep old rows and ignore any duplicates. But you may use the mode argument and set it to "replace" (replace old rows) or "truncate" (delete old rows from database table before writing data). If you are using a non MySQL connection, you may notice that this feature is not available yet.

Unstable connections
--------------------

One of the problems we face on a regular basis are connection problems to external servers. To address this `sendQuery` will evaluate everything in a 'try-catch' handler abstracted in `dbtools::reTry`. With this you can state how many tries a query has, how many seconds should be waited between each iteration and how the error messages should be logged:

``` r
dat <- sendQuery(
  cred, 
  "SELECT * FROM USArrest;", # wrong name for illustration
  tries = 2,
  intSleep = 1
)
```

    ## ERROR [2018-03-08 11:23:02] Error in rsqlite_send_query(conn@ptr, statement) : 
    ##   no such table: USArrest
    ## 
    ## ERROR [2018-03-08 11:23:03] Error in rsqlite_send_query(conn@ptr, statement) : 
    ##   no such table: USArrest

    ## Error in reTry(..., fun = function(...) {: Error in rsqlite_send_query(conn@ptr, statement) : 
    ##   no such table: USArrest

Multiple Databases
------------------

Sometimes your data can be distributed on different servers but you want to send the same query to those servers. What you can do is give `sendQuery` a *CredentialsList*.

``` r
file.copy("example.db", "example1.db")
```

Now we want to load the data from `example1.db` and `example.db` which can be implemented as follows:

``` r
cred <- Credentials(
  RSQLite::SQLite, 
  dbname = c("example.db", "example1.db")
)

sendQuery(cred, "SELECT * FROM USArrests;")
```

    ##              State Murder Assault UrbanPop Rape
    ##   1:       Alabama   13.2     236       58 21.2
    ##   2:        Alaska   10.0     263       48 44.5
    ##   3:       Arizona    8.1     294       80 31.0
    ##   4:      Arkansas    8.8     190       50 19.5
    ##   5:    California    9.0     276       91 40.6
    ##  ---                                           
    ##  96:      Virginia    8.5     156       63 20.7
    ##  97:    Washington    4.0     145       73 26.2
    ##  98: West Virginia    5.7      81       39  9.3
    ##  99:     Wisconsin    2.6      53       66 10.8
    ## 100:       Wyoming    6.8     161       60 15.6

It might also be of interest to query your databases in parallel. For that it is possible to supply a apply/map function which in turn can be a parallel lapply like mclapply or something else:

``` r
sendQuery(
  cred, 
  "SELECT * FROM USArrests;", 
  mc.cores = 2, 
  applyFun = parallel::mclapply
)
```

    ##              State Murder Assault UrbanPop Rape
    ##   1:       Alabama   13.2     236       58 21.2
    ##   2:        Alaska   10.0     263       48 44.5
    ##   3:       Arizona    8.1     294       80 31.0
    ##   4:      Arkansas    8.8     190       50 19.5
    ##   5:    California    9.0     276       91 40.6
    ##  ---                                           
    ##  96:      Virginia    8.5     156       63 20.7
    ##  97:    Washington    4.0     145       73 26.2
    ##  98: West Virginia    5.7      81       39  9.3
    ##  99:     Wisconsin    2.6      53       66 10.8
    ## 100:       Wyoming    6.8     161       60 15.6

Potentially you can send multiple queries to multiple databases. The results are tried to be simplified by default:

``` r
sendQuery(cred, c("SELECT * FROM USArrests;", "SELECT 1 AS x;"))
```

    ## [[1]]
    ##              State Murder Assault UrbanPop Rape
    ##   1:       Alabama   13.2     236       58 21.2
    ##   2:        Alaska   10.0     263       48 44.5
    ##   3:       Arizona    8.1     294       80 31.0
    ##   4:      Arkansas    8.8     190       50 19.5
    ##   5:    California    9.0     276       91 40.6
    ##  ---                                           
    ##  96:      Virginia    8.5     156       63 20.7
    ##  97:    Washington    4.0     145       73 26.2
    ##  98: West Virginia    5.7      81       39  9.3
    ##  99:     Wisconsin    2.6      53       66 10.8
    ## 100:       Wyoming    6.8     161       60 15.6
    ## 
    ## [[2]]
    ##    x
    ## 1: 1
    ## 2: 1

``` r
sendQuery(cred, c("SELECT * FROM USArrests;", "SELECT 1 AS x;"), simplify = FALSE)
```

    ## [[1]]
    ## [[1]][[1]]
    ##             State Murder Assault UrbanPop Rape
    ##  1:       Alabama   13.2     236       58 21.2
    ##  2:        Alaska   10.0     263       48 44.5
    ##  3:       Arizona    8.1     294       80 31.0
    ##  4:      Arkansas    8.8     190       50 19.5
    ##  5:    California    9.0     276       91 40.6
    ## ---                                           
    ## 46:      Virginia    8.5     156       63 20.7
    ## 47:    Washington    4.0     145       73 26.2
    ## 48: West Virginia    5.7      81       39  9.3
    ## 49:     Wisconsin    2.6      53       66 10.8
    ## 50:       Wyoming    6.8     161       60 15.6
    ## 
    ## [[1]][[2]]
    ##             State Murder Assault UrbanPop Rape
    ##  1:       Alabama   13.2     236       58 21.2
    ##  2:        Alaska   10.0     263       48 44.5
    ##  3:       Arizona    8.1     294       80 31.0
    ##  4:      Arkansas    8.8     190       50 19.5
    ##  5:    California    9.0     276       91 40.6
    ## ---                                           
    ## 46:      Virginia    8.5     156       63 20.7
    ## 47:    Washington    4.0     145       73 26.2
    ## 48: West Virginia    5.7      81       39  9.3
    ## 49:     Wisconsin    2.6      53       66 10.8
    ## 50:       Wyoming    6.8     161       60 15.6
    ## 
    ## 
    ## [[2]]
    ## [[2]][[1]]
    ##    x
    ## 1: 1
    ## 
    ## [[2]][[2]]
    ##    x
    ## 1: 1

Both functionalities are available for `sendData`, too.

Parameterized Queries
---------------------

In many applications it is easier and more tangible to separate SQL and R code. Furthermore we oftentimes paste queries together to have something like parameterized statements. There are various solutions for this type of problem but not many for the R language. Hence `dbtools` provides an own interface to what may be understood as *template queries*. These templates solve two issues for us:

1.  Put SQL code where it belongs: a `.sql` file.
2.  Provide a simple way to pass objects to these queries, using parameters.

The use of these features is simple enough. A template is defined as a character and regions in which parameters are substituted are denoted by two curly braces. Users of [Liquid templates](http://shopify.github.io/liquid/) may be familiar with this idea. Everything inside these regions is interpreted as R-expression and can contain arbitrary operations. The result of the evaluation should be a character of length one.

``` r
templateQuery <- "SELECT {{ sqlName(fieldName) }} FROM `someTable`;"
Query(templateQuery, fieldName = "someField")
```

    ## Query:
    ## SELECT `someField` FROM `someTable`;

When such a query lives inside a file we can use a connection object and pass it to `Query`.

``` r
otherTemplateQuery <-
  "SELECT `someField` FROM `someTable` WHERE `primaryKey` IN {{ sqlInNums(ids) }};"
writeLines(otherTemplateQuery, tmpFile <- tempfile())
Query(file(tmpFile), ids = 1:10)
```

    ## Query:
    ## SELECT `someField` FROM `someTable` WHERE `primaryKey` IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

``` r
unlink(c("example.db", "example1.db"))
```
