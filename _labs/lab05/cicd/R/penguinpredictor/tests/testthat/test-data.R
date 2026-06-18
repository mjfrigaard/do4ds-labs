library(penguinpredictor)

# --- encode_inputs ---

test_that("encode_inputs returns a list", {
  result <- encode_inputs(45.0, "Adelie", "Male")
  expect_type(result, "list")
})

test_that("bill_length_mm is numeric", {
  result <- encode_inputs(45L, "Adelie", "Male")
  expect_type(result$bill_length_mm, "double")
})

test_that("Adelie Male encoding is correct", {
  result <- encode_inputs(45.0, "Adelie", "Male")
  expect_equal(result$bill_length_mm, 45.0)
  expect_equal(result$species_Chinstrap, 0L)
  expect_equal(result$species_Gentoo, 0L)
  expect_equal(result$sex_male, 1L)
})

test_that("Chinstrap Female encoding is correct", {
  result <- encode_inputs(39.5, "Chinstrap", "Female")
  expect_equal(result$bill_length_mm, 39.5)
  expect_equal(result$species_Chinstrap, 1L)
  expect_equal(result$species_Gentoo, 0L)
  expect_equal(result$sex_male, 0L)
})

test_that("Gentoo Male encoding is correct", {
  result <- encode_inputs(50.0, "Gentoo", "Male")
  expect_equal(result$species_Chinstrap, 0L)
  expect_equal(result$species_Gentoo, 1L)
  expect_equal(result$sex_male, 1L)
})

test_that("encode_inputs returns expected keys", {
  result <- encode_inputs(45.0, "Adelie", "Male")
  expect_named(result, c("bill_length_mm", "species_Chinstrap", "species_Gentoo", "sex_male"))
})

# --- validate_inputs ---

test_that("valid inputs return no errors", {
  expect_length(validate_inputs(45.0, "Adelie", "Male"), 0)
  expect_length(validate_inputs(30.0, "Chinstrap", "Female"), 0)
  expect_length(validate_inputs(60.0, "Gentoo", "Male"), 0)
})

test_that("bill_length too low returns one error", {
  errors <- validate_inputs(29.9, "Adelie", "Male")
  expect_length(errors, 1)
  expect_match(errors[1], "bill_length_mm")
})

test_that("bill_length too high returns one error", {
  errors <- validate_inputs(60.1, "Adelie", "Male")
  expect_length(errors, 1)
  expect_match(errors[1], "bill_length_mm")
})

test_that("bill_length at boundaries is valid", {
  expect_length(validate_inputs(30.0, "Adelie", "Male"), 0)
  expect_length(validate_inputs(60.0, "Adelie", "Male"), 0)
})

test_that("invalid species returns one error", {
  errors <- validate_inputs(45.0, "Emperor", "Male")
  expect_length(errors, 1)
  expect_match(errors[1], "species")
  expect_match(errors[1], "Emperor")
})

test_that("invalid sex returns one error", {
  errors <- validate_inputs(45.0, "Adelie", "Unknown")
  expect_length(errors, 1)
  expect_match(errors[1], "sex")
})

test_that("multiple invalid inputs return multiple errors", {
  errors <- validate_inputs(99.0, "Emperor", "Unknown")
  expect_length(errors, 3)
})

test_that("all valid species are accepted", {
  lapply(c("Adelie", "Chinstrap", "Gentoo"), function(sp) {
    expect_length(validate_inputs(45.0, sp, "Male"), 0)
  })
})

test_that("both sexes are accepted", {
  expect_length(validate_inputs(45.0, "Adelie", "Male"), 0)
  expect_length(validate_inputs(45.0, "Adelie", "Female"), 0)
})

# --- parse_prediction ---

test_that(".pred key returns correct value", {
  expect_equal(parse_prediction(list(.pred = list(4180.8))), 4180.8, tolerance = 1e-5)
})

test_that("predict key returns correct value", {
  expect_equal(parse_prediction(list(predict = list(4180.8))), 4180.8, tolerance = 1e-5)
})

test_that("parse_prediction returns numeric", {
  result <- parse_prediction(list(.pred = list(4180L)))
  expect_type(result, "double")
})

test_that(".pred key takes precedence over predict", {
  result <- parse_prediction(list(.pred = list(100.0), predict = list(999.0)))
  expect_equal(result, 100.0, tolerance = 1e-5)
})

test_that("unknown format raises an error", {
  expect_error(parse_prediction(list(result = list(4180.8))), "Unexpected response format")
})

test_that("empty response raises an error", {
  expect_error(parse_prediction(list()))
})
