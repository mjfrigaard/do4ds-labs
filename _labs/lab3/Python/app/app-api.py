from shiny import App, render, ui, reactive
import requests

api_url = 'http://127.0.0.1:8080/predict'

app_ui = ui.page_fluid(
    ui.panel_title("Penguin Mass Predictor"), 
    ui.layout_sidebar(
        ui.panel_sidebar([
            ui.input_slider("bill_length", "Bill Length (mm)", 30, 60, 45, step=0.1),
            ui.input_select("sex", "Sex", ["Male", "Female"]),
            ui.input_select("species", "Species", ["Adelie", "Chinstrap", "Gentoo"]),
            ui.input_action_button("predict", "Predict")
        ]),
        ui.panel_main([
            ui.h2("Penguin Parameters"),
            ui.output_text_verbatim("vals_out"),
            ui.h2("Predicted Penguin Mass (g)"), 
            ui.output_text("pred_out")
        ])
    )   
)

def server(input, output, session):
    @reactive.Calc
    def vals():
        d = {
            "bill_length_mm": input.bill_length(),
            "species_Chinstrap": 1 if input.species() == "Chinstrap" else 0,  # Convert to numeric
            "species_Gentoo": 1 if input.species() == "Gentoo" else 0,        # Convert to numeric  
            "sex_male": 1 if input.sex() == "Male" else 0                     # Convert to numeric (note: sex_male not sex_Male)
        }
        return d
    
    @reactive.Calc
    @reactive.event(input.predict)
    def pred():
        try:
            print(f"Sending data to API: {vals()}")  # Debug print
            r = requests.post(api_url, json=vals())
            r.raise_for_status()  # Raise an exception for bad status codes
            result = r.json()
            print(f"API response: {result}")  # Debug print
            
            # Handle different possible response formats
            if '.pred' in result:
                return result['.pred'][0]
            elif 'predict' in result:
                return result['predict'][0]
            else:
                return f"Unexpected response format: {result}"
                
        except requests.exceptions.RequestException as e:
            return f"API Error: {str(e)}"
        except (KeyError, IndexError, TypeError) as e:
            return f"Response parsing error: {str(e)}"

    @output
    @render.text
    def vals_out():
        return f"{vals()}"

    @output
    @render.text
    def pred_out():
        result = pred()
        if isinstance(result, (int, float)):
            return f"{round(result, 1)} grams"
        else:
            return str(result)  # Show error messages

app = App(app_ui, server)