import logging
from pathlib import Path


def setup_logging(log_dir="logs", level=logging.INFO):
    """Configure logging with file and console output.

    Creates the log directory if it does not exist and returns the path
    to the log file.
    """
    log_path = Path(log_dir)
    log_path.mkdir(exist_ok=True)
    log_file = log_path / "shiny_app.log"

    logging.basicConfig(
        level=level,
        format="%(asctime)s - %(levelname)s - %(message)s",
        handlers=[
            logging.FileHandler(log_file, mode="a"),
            logging.StreamHandler(),
        ],
    )
    return str(log_file)
