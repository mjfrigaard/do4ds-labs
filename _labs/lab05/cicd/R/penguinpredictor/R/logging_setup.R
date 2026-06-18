#' Configure logging with file and console output
#'
#' Creates the log directory if it does not exist and returns the path
#' to the log file.
#'
#' @param log_dir character path to log directory
#' @param level log threshold level (default logger::INFO)
#' @return character path to log file (invisibly)
#' @export
setup_logging <- function(log_dir = "logs", level = logger::INFO) {
  if (!dir.exists(log_dir)) {
    dir.create(log_dir, recursive = TRUE)
  }
  log_file <- file.path(log_dir, "shiny_app.log")

  logger::log_appender(logger::appender_tee(log_file))
  logger::log_threshold(level)
  logger::log_layout(logger::layout_glue_generator(
    format = "{time} - {level} - {msg}"
  ))

  invisible(log_file)
}
