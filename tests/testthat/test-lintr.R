testthat::context("Package Style")
# nolint start
test_that("Package Style", {
  suppressWarnings(lintr::expect_lint_free(
    relative_path = FALSE,
    linters = list(
      a = lintr::assignment_linter(),
      b = lintr::commas_linter(),
      c = lintr::commented_code_linter(),
      d = lintr::infix_spaces_linter(),
      e = lintr::line_length_linter(100),
      f = lintr::no_tab_linter(),
      # g = lintr::object_name_linter("camelCase"),
      h = lintr::object_length_linter()
      # i = lintr::spaces_left_parentheses_linter #has problems with x@fun()
    )
  ))
})
# nolint end
