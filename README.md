[![Travis-CI Build Status](https://travis-ci.org/INWT/dbtools.svg?branch=master)](https://travis-ci.org/INWT/dbtools)

This package abstracts typical patterns used when connecting to and retrieving
data from databases in R. It aims to provide very few, simple and reliable
functions for sending queries and data to databases.

## Installation


```r
# currently we will rely on the development version of aoos which will change in
# the near future
devtools::install_github("wahani/aoos")
devtools::install_github("INWT/dbtools")
```


## Basic usage: sendQuery

For basic usage consider the simple case where we want to retrieve some data
from a SQLite database. At this time we only have `sendQuery` and no `sendData`
so we use the standard example for setting up the database:


```r
library("RSQLite")
con <- dbConnect(SQLite(), "example.db")
data(USArrests)
dbWriteTable(con, "USArrests", USArrests)
dbDisconnect(con)
```

This will create a database `example.db` to which we can send some queries. To
begin with, we have to define an object of class *Credentials* which will store
all necessary information to connect to a database. The driver is mandatory, all
other arguments depend on the specific back-end.


```r
library("dbtools")
cred <- Credentials(drv = RSQLite::SQLite, dbname = "example.db")
cred
```

```
## An object of class "Credentials"
## drv : SQLiteDriver 
## dbname : example.db
```

Opposed to the `dbSendQuery` function available from DBI, `sendQuery` needs a
*Credentials* instance as argument and will take care of connecting to the
database, fetching the results and closing the connection.


```r
dat <- sendQuery(cred, "SELECT * FROM USArrests;")
dat
```

```
## Source: local data frame [50 x 5]
## 
##      row_names Murder Assault UrbanPop  Rape
##          (chr)  (dbl)   (int)    (int) (dbl)
## 1      Alabama   13.2     236       58  21.2
## 2       Alaska   10.0     263       48  44.5
## 3      Arizona    8.1     294       80  31.0
## 4     Arkansas    8.8     190       50  19.5
## 5   California    9.0     276       91  40.6
## 6     Colorado    7.9     204       78  38.7
## 7  Connecticut    3.3     110       77  11.1
## 8     Delaware    5.9     238       72  15.8
## 9      Florida   15.4     335       80  31.9
## 10     Georgia   17.4     211       60  25.8
## ..         ...    ...     ...      ...   ...
```

In your normal workflow you will sometimes want to split up a complex query into
more tangible chunks. The approach we take here is to allow for a vector of
queries as argument. The result of these queries have to be *row-bindable*. To
make an example lets say we want to query each state separately:


```r
queryFun <- function(state) {
  paste0("SELECT * FROM USArrests WHERE row_names = '", state, "';")
}

sendQuery(cred, queryFun(dat$row_names))
```

```
## Source: local data frame [50 x 5]
## 
##      row_names Murder Assault UrbanPop  Rape
##          (chr)  (dbl)   (int)    (int) (dbl)
## 1      Alabama   13.2     236       58  21.2
## 2       Alaska   10.0     263       48  44.5
## 3      Arizona    8.1     294       80  31.0
## 4     Arkansas    8.8     190       50  19.5
## 5   California    9.0     276       91  40.6
## 6     Colorado    7.9     204       78  38.7
## 7  Connecticut    3.3     110       77  11.1
## 8     Delaware    5.9     238       72  15.8
## 9      Florida   15.4     335       80  31.9
## 10     Georgia   17.4     211       60  25.8
## ..         ...    ...     ...      ...   ...
```

In such a case `sendQuery` will perform all queries on one connection. A 
different approach is to fetch the results of the original query in chunks,
which we do not support yet.


## Unstable connections

One of the problems we face on a regular basis are connection problems to
external servers. To address this `sendQuery` will evaluate everything in a
'try-catch' handler abstracted in `dbtools::reTry`. With this you can state how
many tries a query has, how many seconds should be waited between each iteration
and how the error messages should be logged:


```r
dat <- sendQuery(
  cred, 
  "SELECT * FROM USArrest;", # wrong name for illustration
  tries = 2,
  intSleep = 1
)
```

```
## ERROR [2015-09-30 14:07:07] Error in sqliteSendQuery(conn, statement) : 
##   error in statement: no such table: USArrest
## 
## ERROR [2015-09-30 14:07:08] Error in sqliteSendQuery(conn, statement) : 
##   error in statement: no such table: USArrest
```


## Multiple Databases

Sometimes your data can be distributed on different servers but you want to send
the same query to those servers. What you can do is give `sendQuery` a
*CredentialsList*. 


```r
con <- dbConnect(SQLite(), "example1.db")
data(USArrests)
dbWriteTable(con, "USArrests", USArrests)
dbDisconnect(con)
```

Now we want to load the data from `example1.db` and `example.db` which can be
implemented as follows:


```r
cred <- Credentials(
  RSQLite::SQLite, 
  dbname = c("example.db", "example1.db")
)

sendQuery(cred, "SELECT * FROM USArrests;")
```

```
## Source: local data frame [100 x 5]
## 
##      row_names Murder Assault UrbanPop  Rape
##          (chr)  (dbl)   (int)    (int) (dbl)
## 1      Alabama   13.2     236       58  21.2
## 2       Alaska   10.0     263       48  44.5
## 3      Arizona    8.1     294       80  31.0
## 4     Arkansas    8.8     190       50  19.5
## 5   California    9.0     276       91  40.6
## 6     Colorado    7.9     204       78  38.7
## 7  Connecticut    3.3     110       77  11.1
## 8     Delaware    5.9     238       72  15.8
## 9      Florida   15.4     335       80  31.9
## 10     Georgia   17.4     211       60  25.8
## ..         ...    ...     ...      ...   ...
```


