from shiny import App, render, ui, reactive
import requests

api_url = 'http://127.0.0.1:8080/predict'

app_ui = ui.page_fluid(
    ui.h1("Penguin Mass Predictor"),
    ui.layout_columns(
        ui.card(
            ui.card_header("Inputs"),
            ui.input_slider(id="bill_length", label="Bill Length (mm)", min=30, max=60, value=45, step=0.1),
            ui.input_select(id="sex", label="Sex", choices=["Male", "Female"]),
            ui.input_select(id="species", label="Species", choices=["Adelie", "Chinstrap", "Gentoo"]),
            ui.input_action_button(id="predict", label="Predict")
        ),
        ui.card(
            ui.card_header("Results"),
            ui.h3("Input Values"),
            ui.output_text_verbatim(id="vals_out"),
            ui.h3("Species Encoding"),
            ui.output_text(id="species_debug"),
            ui.h3("API Connection"),
            ui.output_text(id="api_status"),
            ui.h3("Predicted Mass"),
            ui.output_text(id="pred_out")
        ),
        col_widths=[4, 8]
    )
)

def server(input, output, session):
    @reactive.calc
    def vals():
        # Create data in LIST format (what API expects)
        d = [{
            "bill_length_mm": int(input.bill_length()),
            "species_Chinstrap": int(input.species() == "Chinstrap"),
            "species_Gentoo": int(input.species() == "Gentoo"),
            "sex_male": int(input.sex() == "Male")
        }]
        return d
    
    @reactive.calc
    def api_health_check():
        """Check if API is responsive"""
        try:
            ping_url = 'http://127.0.0.1:8080/ping'
            r = requests.get(ping_url, timeout=5)
            if r.status_code == 200:
                return f"✅ API is running (ping: {r.json()})"
            else:
                return f"⚠️ API ping failed: {r.status_code}"
        except requests.exceptions.ConnectionError:
            return "❌ Cannot connect to API - is it running on port 8080?"
        except Exception as e:
            return f"❌ API health check failed: {str(e)}"
    
    @reactive.calc
    @reactive.event(input.predict)
    def pred():
        try:
            data_to_send = vals()
            print(f"\n=== PREDICTION REQUEST ===")
            print(f"Sending data to API: {data_to_send}")
            
            r = requests.post(api_url, json=data_to_send, timeout=30)
            print(f"HTTP Status Code: {r.status_code}")
            print(f"Raw response text: {r.text}")
            
            if r.status_code == 200:
                result = r.json()
                print(f"✅ Success! Parsed response: {result}")
                
                # Handle different possible response formats  
                if '.pred' in result:
                    prediction = result['.pred'][0]
                    return prediction
                elif 'predict' in result:
                    prediction = result['predict'][0]
                    return prediction
                else:
                    return f"Unexpected response format: {result}"
            else:
                return f"API Error {r.status_code}: {r.text}"
                
        except Exception as e:
            print(f"❌ Error: {e}")
            return f"Error: {str(e)}"

    @render.text
    def vals_out():
        data = vals()
        return f"{data}"
    
    @render.text
    def species_debug():
        species = input.species()
        chinstrap = int(species == "Chinstrap")
        gentoo = int(species == "Gentoo")
        
        if chinstrap == 0 and gentoo == 0:
            return f"Selected: {species} → Adelie (reference category)"
        elif chinstrap == 1:
            return f"Selected: {species} → Chinstrap"
        elif gentoo == 1:
            return f"Selected: {species} → Gentoo"
    
    @render.text
    def api_status():
        return api_health_check()

    @render.text
    def pred_out():
        result = pred()
        if isinstance(result, (int, float)):
            return f"{round(result, 1)} grams"
        else:
            return str(result)

app = App(app_ui, server)