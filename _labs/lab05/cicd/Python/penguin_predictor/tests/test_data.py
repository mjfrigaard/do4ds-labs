import pytest
from penguin_predictor.data import encode_inputs, validate_inputs, parse_prediction


# --- encode_inputs ---

class TestEncodeInputs:

    def test_returns_list_of_one_dict(self):
        result = encode_inputs(45.0, "Adelie", "Male")
        assert isinstance(result, list)
        assert len(result) == 1
        assert isinstance(result[0], dict)

    def test_bill_length_is_float(self):
        result = encode_inputs(45, "Adelie", "Male")
        assert isinstance(result[0]["bill_length_mm"], float)

    def test_adelie_male(self):
        result = encode_inputs(45.0, "Adelie", "Male")[0]
        assert result["bill_length_mm"] == 45.0
        assert result["species_Chinstrap"] == 0
        assert result["species_Gentoo"] == 0
        assert result["sex_male"] == 1

    def test_chinstrap_female(self):
        result = encode_inputs(39.5, "Chinstrap", "Female")[0]
        assert result["bill_length_mm"] == 39.5
        assert result["species_Chinstrap"] == 1
        assert result["species_Gentoo"] == 0
        assert result["sex_male"] == 0

    def test_gentoo_male(self):
        result = encode_inputs(50.0, "Gentoo", "Male")[0]
        assert result["species_Chinstrap"] == 0
        assert result["species_Gentoo"] == 1
        assert result["sex_male"] == 1

    def test_expected_keys_present(self):
        result = encode_inputs(45.0, "Adelie", "Male")[0]
        assert set(result.keys()) == {
            "bill_length_mm",
            "species_Chinstrap",
            "species_Gentoo",
            "sex_male",
        }


# --- validate_inputs ---

class TestValidateInputs:

    def test_valid_inputs_return_no_errors(self):
        assert validate_inputs(45.0, "Adelie", "Male") == []
        assert validate_inputs(30.0, "Chinstrap", "Female") == []
        assert validate_inputs(60.0, "Gentoo", "Male") == []

    def test_bill_length_too_low(self):
        errors = validate_inputs(29.9, "Adelie", "Male")
        assert len(errors) == 1
        assert "bill_length_mm" in errors[0]

    def test_bill_length_too_high(self):
        errors = validate_inputs(60.1, "Adelie", "Male")
        assert len(errors) == 1
        assert "bill_length_mm" in errors[0]

    def test_bill_length_at_boundaries(self):
        assert validate_inputs(30.0, "Adelie", "Male") == []
        assert validate_inputs(60.0, "Adelie", "Male") == []

    def test_invalid_species(self):
        errors = validate_inputs(45.0, "Emperor", "Male")
        assert len(errors) == 1
        assert "species" in errors[0]
        assert "Emperor" in errors[0]

    def test_invalid_sex(self):
        errors = validate_inputs(45.0, "Adelie", "Unknown")
        assert len(errors) == 1
        assert "sex" in errors[0]

    def test_multiple_errors_collected(self):
        errors = validate_inputs(99.0, "Emperor", "Unknown")
        assert len(errors) == 3

    def test_all_valid_species_accepted(self):
        for species in ("Adelie", "Chinstrap", "Gentoo"):
            assert validate_inputs(45.0, species, "Male") == []

    def test_both_sexes_accepted(self):
        assert validate_inputs(45.0, "Adelie", "Male") == []
        assert validate_inputs(45.0, "Adelie", "Female") == []


# --- parse_prediction ---

class TestParsePrediction:

    def test_pred_key(self):
        assert parse_prediction({".pred": [4180.8]}) == pytest.approx(4180.8)

    def test_predict_key(self):
        assert parse_prediction({"predict": [4180.8]}) == pytest.approx(4180.8)

    def test_returns_float(self):
        result = parse_prediction({".pred": [4180]})
        assert isinstance(result, float)

    def test_pred_key_takes_precedence(self):
        result = parse_prediction({".pred": [100.0], "predict": [999.0]})
        assert result == pytest.approx(100.0)

    def test_unknown_format_raises(self):
        with pytest.raises(ValueError, match="Unexpected response format"):
            parse_prediction({"result": [4180.8]})

    def test_empty_response_raises(self):
        with pytest.raises(ValueError):
            parse_prediction({})
