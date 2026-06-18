VALID_SPECIES <- c("Adelie", "Chinstrap", "Gentoo")
VALID_SEX <- c("Male", "Female")
BILL_LENGTH_MIN <- 30.0
BILL_LENGTH_MAX <- 60.0

#' Validate prediction inputs
#'
#' @param bill_length numeric bill length in mm
#' @param species character species name
#' @param sex character sex
#' @return character vector of error messages (empty if valid)
#' @export
validate_inputs <- function(bill_length, species, sex) {
  errors <- character(0)
  if (bill_length < BILL_LENGTH_MIN || bill_length > BILL_LENGTH_MAX) {
    errors <- c(errors, sprintf(
      "bill_length_mm must be between %.1f and %.1f, got %.1f",
      BILL_LENGTH_MIN, BILL_LENGTH_MAX, bill_length
    ))
  }
  if (!species %in% VALID_SPECIES) {
    errors <- c(errors, sprintf(
      "species must be one of %s, got '%s'",
      paste(sort(VALID_SPECIES), collapse = ", "), species
    ))
  }
  if (!sex %in% VALID_SEX) {
    errors <- c(errors, sprintf(
      "sex must be one of %s, got '%s'",
      paste(sort(VALID_SEX), collapse = ", "), sex
    ))
  }
  errors
}

#' Encode Shiny UI inputs into the API request format
#'
#' The vetiver API trained on dummy-encoded features expects species and sex
#' as binary indicator columns rather than strings.
#'
#' @param bill_length numeric bill length in mm
#' @param species character species name
#' @param sex character sex
#' @return named list with dummy-encoded features
#' @export
encode_inputs <- function(bill_length, species, sex) {
  list(
    bill_length_mm = as.numeric(bill_length),
    species_Chinstrap = as.integer(species == "Chinstrap"),
    species_Gentoo = as.integer(species == "Gentoo"),
    sex_male = as.integer(sex == "Male")
  )
}

#' Extract the numeric prediction from an API response list
#'
#' Handles both the vetiver .pred format and the legacy predict format.
#' Raises an error if neither key is present.
#'
#' @param response_json list parsed from API JSON response
#' @return numeric prediction value
#' @export
parse_prediction <- function(response_json) {
  if (".pred" %in% names(response_json)) {
    return(as.numeric(response_json[[".pred"]][[1]]))
  }
  if ("predict" %in% names(response_json)) {
    return(as.numeric(response_json[["predict"]][[1]]))
  }
  stop(paste("Unexpected response format:", deparse(names(response_json))))
}
