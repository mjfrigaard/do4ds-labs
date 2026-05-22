from shiny import App, render, ui, reactive
import requests
import json
import logging
import time
import os
from datetime import datetime
from pathlib import Path

# configure logging
def setup_logging():
    """Configure logging with file and console output"""
    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)
    
    log_file = log_dir / "shiny_app.log"
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file, mode='a'),
            logging.StreamHandler()
        ]
    )
    
    return str(log_file)

# initialize logging
log_file_path = setup_logging()
logging.info("Shiny for Python application initialized")

# api configuration
api_url = 'http://127.0.0.1:8080/predict'
ping_url = 'http://127.0.0.1:8080/ping'

app_ui = ui.page_fluid(
    ui.div(
        ui.strong("Session: "),
        ui.output_text(id="session_display"),
        style="position: fixed; top: 10px; right: 10px; z-index: 1000; color: #333; background: #fff; padding: 5px; border-radius: 3px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);"
    ),
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
            ui.div(
                ui.output_text("vals_out"),
                style="font-family: 'Monaco', 'Courier New', monospace; font-size: 12px; background-color: #f8f9fa; padding: 10px; border-radius: 5px; max-height: 250px; overflow-y: auto; border: 1px solid #dee2e6; white-space: pre-wrap;"
            ),
            ui.h3("Predicted Mass"),
            ui.div(
                ui.output_text("pred_out"),
                style="font-size: 24px; font-weight: bold; text-align: center; padding: 15px; color: #0066cc;"
            )
        ),
        col_widths=[4, 8]
    ),
    # System Status
    ui.card(
        ui.card_header("System Status"),
        ui.card_body(
            ui.layout_columns(
                ui.div(
                    ui.h4("API Health Check:"),
                    ui.br(),
                    ui.output_text("api_status"),
                    ui.br(),
                    ui.h4("Recent Logs:"),
                    ui.div(
                        ui.output_text("recent_logs_display"),
                        style="font-family: 'Monaco', 'Courier New', monospace; font-size: 12px; background-color: #f8f9fa; padding: 10px; border-radius: 2px; max-height: 250px; overflow-y: auto; border: 2px solid #dee2e6; white-space: pre-wrap;"
                    ),
                    ui.p(
                        "Last updated: ",
                        ui.output_text("log_timestamp"),
                        style="margin-top: 5px; color: #6c757d; font-size: 12px;"
                    )
                ),
                col_widths=[12]
            )
        )
    )
)

def server(input, output, session):
    # generate session ID and log session start
    session_id = f"py_{int(time.time() * 1000) % 100000}"
    logging.info(f"New session started - Session: {session_id}")
    
    # performance tracking reactive values 
    # (keep for error tracking)
    request_times = reactive.value([])
    error_count = reactive.value(0)
    connection_errors = reactive.value(0)
    timeout_errors = reactive.value(0)
    
    # session cleanup
    def on_session_end():
        logging.info(f"Session ended - Session: {session_id}")
    
    session.on_ended(on_session_end)
    
    # input validation with logging
    @reactive.calc
    def vals():
        bill_length = input.bill_length()
        species = input.species()
        sex = input.sex()
        
        # input validation with warnings
        if bill_length < 30 or bill_length > 60:
            logging.warning(f"Bill length out of typical range - Session: {session_id} - bill_length: {bill_length}")
        
        # create data in LIST format 
        # (what API expects)
        d = [{
            "bill_length_mm": float(bill_length),
            "species_Chinstrap": int(species == "Chinstrap"),
            "species_Gentoo": int(species == "Gentoo"),
            "sex_male": int(sex == "Male")
        }]
        
        logging.debug(f"Input data prepared - Session: {session_id} - data: {json.dumps(d)}")
        return d
    
    @reactive.calc
    def api_health_check():
        """Enhanced API health check with logging"""
        try:
            logging.debug(f"Checking API health - Session: {session_id}")
            start_time = time.time()
            
            r = requests.get(ping_url, timeout=5)
            response_time = time.time() - start_time
            
            if r.status_code == 200:
                logging.info(f"API health check successful - Session: {session_id} - response_time: {response_time:.3f}s")
                return f"✅ API is running (ping: {r.json()}) - {response_time:.2f}s"
            else:
                logging.warning(f"API ping failed - Session: {session_id} - status: {r.status_code}")
                return f"⚠️ API ping failed: {r.status_code}"
                
        except requests.exceptions.ConnectionError as e:
            logging.error(f"API connection refused - Session: {session_id} - error: {str(e)}")
            return "❌ Cannot connect to API - is it running on port 8080?"
        except requests.exceptions.Timeout:
            logging.warning(f"API health check timeout - Session: {session_id}")
            return "⚠️ API health check timeout"
        except Exception as e:
            logging.error(f"API health check failed - Session: {session_id} - error: {str(e)}")
            return f"❌ API health check failed: {str(e)}"
    
    @reactive.calc
    @reactive.event(input.predict)
    def pred():
        """Prediction with logging"""
        request_start = time.time()
        data_to_send = vals()
        
        logging.info(f"Starting prediction request - Session: {session_id} - request_data: {json.dumps(data_to_send)}")
        
        try:
            print(f"\n=== PREDICTION REQUEST ===")
            print(f"Sending data to API: {data_to_send}")
            
            r = requests.post(api_url, json=data_to_send, timeout=30)
            response_time = time.time() - request_start
            
            # update performance metrics 
            current_times = request_times()
            current_times.append(response_time)
            if len(current_times) > 10:
                current_times = current_times[-10:]
            request_times.set(current_times)
            
            print(f"HTTP Status Code: {r.status_code}")
            print(f"Raw response text: {r.text}")
            
            if r.status_code == 200:
                result = r.json()
                print(f"✅ Success! Parsed response: {result}")
                
                # handle different possible response formats  
                if '.pred' in result:
                    prediction = result['.pred'][0]
                elif 'predict' in result:
                    prediction = result['predict'][0]
                else:
                    logging.warning(f"Unexpected response format - Session: {session_id} - response: {result}")
                    return f"Unexpected response format: {result}"
                
                logging.info(f"Prediction successful - Session: {session_id} - response_time: {response_time:.3f}s - prediction: {prediction}")
                
                # performance warning
                if response_time > 5:
                    logging.warning(f"Slow API response - Session: {session_id} - response_time: {response_time:.3f}s")
                
                return prediction
            else:
                error_msg = f"API Error {r.status_code}: {r.text}"
                logging.error(f"Prediction request failed - Session: {session_id} - status: {r.status_code} - response: {r.text[:200]}")
                error_count.set(error_count() + 1)
                return error_msg
                
        except requests.exceptions.ConnectionError as e:
            error_msg = f"Connection Error: {str(e)}"
            logging.error(f"API connection refused during prediction - Session: {session_id} - error: {str(e)}")
            connection_errors.set(connection_errors() + 1)
            error_count.set(error_count() + 1)
            print(f"❌ Connection Error: {e}")
            return error_msg
        except requests.exceptions.Timeout:
            error_msg = "Request timed out - API may be overloaded"
            logging.warning(f"API timeout during prediction - Session: {session_id}")
            timeout_errors.set(timeout_errors() + 1)
            error_count.set(error_count() + 1)
            return error_msg
        except Exception as e:
            error_msg = f"Error: {str(e)}"
            logging.error(f"Unknown prediction error - Session: {session_id} - error: {str(e)}")
            error_count.set(error_count() + 1)
            print(f"❌ Error: {e}")
            return error_msg

    # log file monitoring
    @reactive.file_reader(log_file_path)
    def log_file_content():
        """Monitor log file for changes"""
        try:
            with open(log_file_path, 'r') as f:
                lines = f.readlines()
                return {
                    'lines': lines,
                    'last_modified': datetime.now(),
                    'total_lines': len(lines)
                }
        except Exception as e:
            logging.error(f"Error reading log file - Session: {session_id} - error: {str(e)}")
            return {
                'lines': [],
                'last_modified': datetime.now(),
                'total_lines': 0
            }

    # output renderers -------
    @render.text
    def session_display():
        return session_id[:8]

    @render.text
    def vals_out():
        data = vals()
        logging.debug(f"Displaying input values to user - Session: {session_id}")
        return f"{data}"
    
    @render.text
    def api_status():
        return api_health_check()

    @render.text
    def pred_out():
        result = pred()
        if isinstance(result, (int, float)):
            display_value = f"{round(result, 1)} grams"
            logging.info(f"Displaying prediction to user - Session: {session_id} - display_value: {display_value}")
            return display_value
        else:
            return str(result)
    
    @render.text
    def recent_logs_display():
        log_data = log_file_content()
        lines = log_data['lines']
        
        if lines:
            # get last 10 lines for better monitoring
            recent_lines = lines[-10:] if len(lines) > 10 else lines
            clean_lines = [line.rstrip() for line in recent_lines]
            
            logging.debug(f"Updating recent logs display - Session: {session_id} - showing {len(recent_lines)} lines")
            return '\n'.join(clean_lines)
        else:
            return "No logs available yet..."
    
    @render.text
    def log_timestamp():
        log_data = log_file_content()
        return log_data['last_modified'].strftime("%Y-%m-%d %H:%M:%S")

app = App(app_ui, server)

# app creation
logging.info("Shiny for Python application created successfully")