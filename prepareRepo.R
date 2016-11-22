knitr::knit("README.Rmd", "README.md")
rmarkdown::render("README.Rmd")

file.remove(c("example.db", "example1.db"))

library("dbtools")
