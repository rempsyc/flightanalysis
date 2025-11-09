#' Cache Control Function
#'
#' @description
#' Function to store scraped flight data to local CSV files or SQLite database.
#'
#' @param directory Character string specifying the root directory or database file
#' @param ... Scrape objects to cache
#' @param use_db Logical. If TRUE, uses SQLite database. If FALSE, uses CSV files
#'
#' @return Invisibly returns NULL
#' @export
#'
#' @examples
#' \dontrun{
#' scrape <- Scrape("JFK", "IST", "2023-07-20", "2023-08-20")
#' # After scraping:
#' # CacheControl("./cache/", scrape, use_db = FALSE)
#' }
CacheControl <- function(directory, ..., use_db = FALSE) {
  scrape_objects <- list(...)
  
  # Check and prepare directory
  dir_info <- check_dir(directory)
  directory <- dir_info$directory
  access_dir <- dir_info$access_dir
  
  # Process each Scrape object
  for (obj in scrape_objects) {
    if (check_scrape(obj)) {
      cache_data(obj, directory, access_dir, use_db)
    }
  }
  
  invisible(NULL)
}

#' Cache Data for a Scrape Object
#' 
#' @param obj Scrape object
#' @param directory Directory path or database path
#' @param access_dir Access metadata directory
#' @param use_db Logical for database usage
#' @keywords internal
cache_data <- function(obj, directory, access_dir, use_db) {
  if (nrow(obj$data) == 0) {
    warning("Scrape object has no data to cache")
    return(invisible(NULL))
  }
  
  fname <- paste0(directory, get_file_name(obj$origin[[1]], obj$dest[[1]], access = FALSE))
  access <- paste0(access_dir, get_file_name(obj$origin[[1]], obj$dest[[1]], access = TRUE))
  df <- obj$data
  current_access <- format(Sys.time(), "%Y-%m-%d")
  
  if (use_db) {
    # Database caching
    if (!file.exists(directory)) {
      message("DB does not exist, creating DB file")
      file.create(directory)
    }
    
    # Note: This requires RSQLite package
    if (requireNamespace("RSQLite", quietly = TRUE)) {
      con <- RSQLite::dbConnect(RSQLite::SQLite(), directory)
      RSQLite::dbWriteTable(con, "flights", df, append = TRUE)
      RSQLite::dbDisconnect(con)
    } else {
      warning("RSQLite package not available. Cannot cache to database.")
    }
    
    return(invisible(NULL))
  }
  
  # File-based caching
  if (file.exists(fname)) {
    # Check if most recent access is today
    if (file.exists(access)) {
      recent_access <- readLines(access, n = 1)
      if (recent_access != current_access) {
        df_old <- read.csv(fname, stringsAsFactors = FALSE)
        df <- rbind(df_old, df)
      } else {
        # Data already in CSV, redundant
        return(invisible(NULL))
      }
    }
  }
  
  write.csv(df, fname, row.names = FALSE)
  writeLines(current_access, access)
  
  invisible(NULL)
}

#' Check if Scrape Object is Valid
#' 
#' @param obj Object to check
#' @keywords internal
check_scrape <- function(obj) {
  inherits(obj, "Scrape")
}

#' Check and Prepare Directory
#' 
#' @param directory Directory path
#' @keywords internal
check_dir <- function(directory) {
  # Add trailing slash if needed and not a .db file
  if (!grepl("/$", directory) && !grepl("\\.db$", directory)) {
    directory <- paste0(directory, "/")
  }
  
  # Initialize .access metadata directory if needed
  access_dir <- paste0(directory, ".access/")
  if (!grepl("\\.db$", directory) && !dir.exists(access_dir)) {
    dir.create(access_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Create main directory if it doesn't exist
  if (!grepl("\\.db$", directory) && !dir.exists(directory)) {
    dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  }
  
  list(directory = directory, access_dir = access_dir)
}

#' Get File Name for Caching
#' 
#' @param airport1 First airport code
#' @param airport2 Second airport code
#' @param access Logical. If TRUE, returns access file name
#' @keywords internal
get_file_name <- function(airport1, airport2, access = FALSE) {
  # Create filename by alphabetical order of 2 airports
  airports <- sort(c(airport1, airport2))
  file <- paste(airports[1], airports[2], sep = "-")
  
  if (access) {
    return(paste0(file, ".txt"))
  }
  return(paste0(file, ".csv"))
}
