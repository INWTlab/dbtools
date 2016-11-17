knitr::knit("README.Rmd", "README.md")
rmarkdown::render("README.Rmd")

file.remove(c("example.db", "example1.db"))

fileName <- tempfile()

writeLines(
  c("SELECT * ",
    "FROM {{ toupper(table) }};",
    "",
    "SELECT * ",
    "FROM {{ toupper(table) }};"    
  ),
  fileName
)

query <- Query(file(fileName))

Query(query, table = "jup")



fileName <- tempfile()

writeLines(
  c("SELECT","{{ value }};"),
  fileName
)

query <- Query(file(fileName), value = 1)

cred <- Credentials(drv = RSQLite::SQLite, dbname = ":memory:")
dat <- sendQuery(cred, query)
