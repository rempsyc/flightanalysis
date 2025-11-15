#' Plot Best Travel Dates
#'
#' @description
#' Creates a bar chart showing the best (cheapest) travel dates identified by
#' \code{\link{fa_find_best_dates}}. Each bar represents a date-origin combination,
#' with bars colored by origin airport. This makes it easy to visually compare
#' the best options and see which dates and origins offer the lowest prices.
#'
#' @param best_dates A data frame from \code{\link{fa_find_best_dates}} or
#'   flight results that can be passed to \code{\link{fa_find_best_dates}}.
#' @param title Character. Plot title. Default is "Best Travel Dates by Price".
#' @param ... Additional arguments passed to \code{\link{fa_find_best_dates}}
#'   if best_dates is not already a result from that function.
#'
#' @return Invisibly returns the best dates data frame used for plotting.
#'
#' @export
#'
#' @examples
#' # Plot best dates
#' fa_plot_best_dates(sample_flights, n = 5)
#'
#' # With filters
#' fa_plot_best_dates(sample_flights, n = 5, max_stops = 0)
fa_plot_best_dates <- function(
  best_dates,
  title = "Best Travel Dates by Price",
  ...
) {
  # If not already a best_dates result, create it
  if (!("price" %in% names(best_dates))) {
    best_dates <- fa_find_best_dates(best_dates, ...)
  }
  
  if (nrow(best_dates) == 0) {
    stop("No data to plot after filtering")
  }
  
  # Extract relevant columns
  has_origin <- "origin" %in% names(best_dates)
  
  # Create labels for x-axis
  if ("departure_date" %in% names(best_dates) && "departure_time" %in% names(best_dates)) {
    # Use date and time for label
    date_labels <- paste0(
      format(as.Date(best_dates$departure_date), "%m/%d"),
      "\n",
      best_dates$departure_time
    )
  } else if ("date" %in% names(best_dates)) {
    # Use just date
    date_labels <- format(as.Date(best_dates$date), "%m/%d")
  } else if ("departure_date" %in% names(best_dates)) {
    date_labels <- format(as.Date(best_dates$departure_date), "%m/%d")
  } else {
    # Fallback to row numbers
    date_labels <- seq_len(nrow(best_dates))
  }
  
  # Get prices
  prices <- best_dates$price
  
  # Set up colors by origin if available
  if (has_origin) {
    origins <- best_dates$origin
    unique_origins <- unique(origins)
    colors <- c("blue", "red", "green", "purple", "orange", "brown")
    origin_colors <- colors[seq_along(unique_origins) %% length(colors) + 1]
    names(origin_colors) <- unique_origins
    bar_colors <- origin_colors[origins]
  } else {
    bar_colors <- "steelblue"
  }
  
  # Create bar plot
  bar_positions <- barplot(
    prices,
    names.arg = date_labels,
    col = bar_colors,
    border = NA,
    main = title,
    xlab = if ("departure_time" %in% names(best_dates)) "Date & Time" else "Date",
    ylab = "Price ($)",
    las = 1,
    cex.names = 0.8
  )
  
  # Add price labels on top of bars
  text(
    bar_positions,
    prices + max(prices) * 0.02,
    labels = paste0("$", prices),
    cex = 0.8,
    font = 2
  )
  
  # Add legend if we have multiple origins
  if (has_origin && length(unique_origins) > 1) {
    legend(
      "topright",
      legend = unique_origins,
      fill = origin_colors,
      border = NA,
      cex = 0.8,
      bg = "white"
    )
  }
  
  # Add grid for readability
  grid(nx = NA, ny = NULL)
  
  invisible(best_dates)
}
