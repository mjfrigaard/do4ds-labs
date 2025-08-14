# pkgs
import vetiver
import pins

# connect to model board
model_board = pins.board_folder("../../../lab2/R/models/")

# read pinned vetiver model
v = vetiver.vetiver_pin_read(model_board, "penguin_model")

# use FastAPI/vetiver to create router/create API
app = vetiver.VetiverAPI(v)
