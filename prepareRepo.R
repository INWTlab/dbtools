rmarkdown::render("README.Rmd")
file.remove(c("example.db", "example1.db"))

library("dbtools")
