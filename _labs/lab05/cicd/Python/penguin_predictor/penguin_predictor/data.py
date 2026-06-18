VALID_SPECIES = {"Adelie", "Chinstrap", "Gentoo"}
VALID_SEX = {"Male", "Female"}
BILL_LENGTH_MIN = 30.0
BILL_LENGTH_MAX = 60.0


def validate_inputs(bill_length, species, sex):
    """Validate prediction inputs. Returns a list of error messages (empty if valid)."""
    errors = []
    if not BILL_LENGTH_MIN <= bill_length <= BILL_LENGTH_MAX:
        errors.append(
            f"bill_length_mm must be between {BILL_LENGTH_MIN} and "
            f"{BILL_LENGTH_MAX}, got {bill_length}"
        )
    if species not in VALID_SPECIES:
        errors.append(
            f"species must be one of {sorted(VALID_SPECIES)}, got '{species}'"
        )
    if sex not in VALID_SEX:
        errors.append(
            f"sex must be one of {sorted(VALID_SEX)}, got '{sex}'"
        )
    return errors


def encode_inputs(bill_length, species, sex):
    """Encode Shiny UI inputs into the API request format.

    The vetiver API trained on dummy-encoded features expects species and sex
    as binary indicator columns rather than strings.
    """
    return [{
        "bill_length_mm": float(bill_length),
        "species_Chinstrap": int(species == "Chinstrap"),
        "species_Gentoo": int(species == "Gentoo"),
        "sex_male": int(sex == "Male"),
    }]


def parse_prediction(response_json):
    """Extract the numeric prediction from an API response dict.

    Handles both the vetiver .pred format and the legacy predict format.
    Raises ValueError if neither key is present.
    """
    if ".pred" in response_json:
        return float(response_json[".pred"][0])
    if "predict" in response_json:
        return float(response_json["predict"][0])
    raise ValueError(f"Unexpected response format: {response_json}")
