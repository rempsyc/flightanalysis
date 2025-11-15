#' Plot Price Summary
#'
#' @description
#' Creates a line plot showing price trends across dates for different origins/cities.
#' This visualizes the output from \code{\link{fa_summarize_prices}}, making it easy
#' to compare prices across dates and identify the best travel dates visually.
#' The cheapest date is highlighted with a marker.
#'
#' @param price_summary A data frame from \code{\link{fa_summarize_prices}} or
#'   flight results that can be passed to \code{\link{fa_summarize_prices}}.
#' @param title Character. Plot title. Default is "Flight Prices by Date".
#' @param highlight_best Logical. If TRUE, highlights the cheapest date(s) with
#'   a marker. Default is TRUE.
#' @param ... Additional arguments passed to \code{\link{fa_summarize_prices}}
#'   if price_summary is not already a summary table.
#'
#' @return Invisibly returns the price summary data frame used for plotting.
#'
#' @export
#'
#' @examples
#' # Plot price summary
#' fa_plot_prices(sample_flights)
#'
#' # With custom title
#' fa_plot_prices(sample_flights, title = "Flight Prices: BOM/DEL to JFK")
fa_plot_prices <- function(
  price_summary,
  title = "Flight Prices by Date",
  highlight_best = TRUE,
  ...
) {
  # If not already a summary table, create it
  if (!all(c("City", "Origin") %in% names(price_summary))) {
    price_summary <- fa_summarize_prices(price_summary, ...)
  }
  
  # Remove the "Best" row if present
  price_summary <- price_summary[price_summary$City != "Best", ]
  
  if (nrow(price_summary) == 0) {
    stop("No data to plot after filtering")
  }
  
  # Identify date columns (format YYYY-MM-DD)
  date_cols <- grep("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", names(price_summary), value = TRUE)
  
  if (length(date_cols) == 0) {
    stop("No date columns found in price_summary")
  }
  
  # Extract price values (remove currency symbols and convert to numeric)
  price_data <- price_summary[, date_cols, drop = FALSE]
  for (col in date_cols) {
    price_data[[col]] <- as.numeric(gsub("[^0-9.]", "", price_data[[col]]))
  }
  
  # Convert dates to Date objects for proper axis formatting
  dates <- as.Date(date_cols)
  
  # Find global min and max prices for y-axis range
  all_prices <- unlist(price_data)
  all_prices <- all_prices[!is.na(all_prices)]
  y_min <- min(all_prices) * 0.95  # Add 5% margin
  y_max <- max(all_prices) * 1.05
  
  # Set up plot
  plot(
    dates,
    rep(NA, length(dates)),
    type = "n",
    xlab = "Date",
    ylab = "Price ($)",
    main = title,
    ylim = c(y_min, y_max),
    xaxt = "n"
  )
  
  # Add x-axis with date formatting
  axis.Date(1, at = dates, format = "%m/%d")
  
  # Define colors for different origins (cycling through if more than 6)
  colors <- c("blue", "red", "green", "purple", "orange", "brown")
  
  # Plot lines for each origin
  for (i in seq_len(nrow(price_summary))) {
    origin_label <- paste0(
      price_summary$City[i],
      " (",
      price_summary$Origin[i],
      ")"
    )
    prices <- as.numeric(price_data[i, ])
    
    # Use color cycling for origins
    col <- colors[((i - 1) %% length(colors)) + 1]
    
    # Plot line
    lines(dates, prices, col = col, lwd = 2)
    
    # Add points
    points(dates, prices, col = col, pch = 19, cex = 1)
    
    # Highlight best (minimum) price for this origin if requested
    if (highlight_best) {
      min_idx <- which.min(prices)
      if (length(min_idx) > 0) {
        points(
          dates[min_idx],
          prices[min_idx],
          col = col,
          pch = 8,
          cex = 2
        )
      }
    }
  }
  
  # Add legend
  origin_labels <- paste0(price_summary$City, " (", price_summary$Origin, ")")
  legend(
    "topright",
    legend = origin_labels,
    col = colors[seq_len(nrow(price_summary)) %% length(colors) + 1],
    lwd = 2,
    cex = 0.8,
    bg = "white"
  )
  
  # Add grid for readability
  grid()
  
  invisible(price_summary)
}
