#' Plot Price Summary
#'
#' @description
#' Creates a modern line plot showing price trends across dates for different origins/cities.
#' This visualizes the output from \code{\link{fa_summarize_prices}}, making it easy
#' to compare prices across dates and identify the best travel dates visually.
#' The cheapest date for each origin is highlighted with a larger point.
#'
#' Uses ggplot2 for a polished, publication-ready aesthetic with colorblind-friendly
#' colors and clear typography.
#'
#' @param price_summary A data frame from \code{\link{fa_summarize_prices}} or
#'   flight results that can be passed to \code{\link{fa_summarize_prices}}.
#' @param title Character. Plot title. Default is "Flight Prices by Date".
#' @param subtitle Character. Plot subtitle. Default is NULL (auto-generated).
#' @param highlight_best Logical. If TRUE, highlights the cheapest date(s) with
#'   a larger point. Default is TRUE.
#' @param ... Additional arguments passed to \code{\link{fa_summarize_prices}}
#'   if price_summary is not already a summary table.
#'
#' @return A ggplot2 plot object that can be further customized or saved.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Plot price summary
#' fa_plot_prices(sample_flights)
#'
#' # With custom title
#' fa_plot_prices(sample_flights, title = "Flight Prices: BOM/DEL to JFK")
#' }
fa_plot_prices <- function(
  price_summary,
  title = "Flight Prices by Date",
  subtitle = NULL,
  highlight_best = TRUE,
  ...
) {
  # Check if ggplot2 is available
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop(
      "Package 'ggplot2' is required for plotting. ",
      "Please install it with: install.packages('ggplot2')"
    )
  }
  if (!requireNamespace("scales", quietly = TRUE)) {
    stop(
      "Package 'scales' is required for plotting. ",
      "Please install it with: install.packages('scales')"
    )
  }
  
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
  
  # Convert to long format for ggplot2
  plot_data <- data.frame()
  for (i in seq_len(nrow(price_summary))) {
    origin_label <- paste0(price_summary$City[i], " (", price_summary$Origin[i], ")")
    for (j in seq_along(date_cols)) {
      plot_data <- rbind(
        plot_data,
        data.frame(
          date = as.Date(date_cols[j]),
          price = as.numeric(price_data[i, j]),
          origin = price_summary$Origin[i],
          origin_label = origin_label,
          stringsAsFactors = FALSE
        )
      )
    }
  }
  
  # Remove any NA prices
  plot_data <- plot_data[!is.na(plot_data$price), ]
  
  # Identify minimum price for each origin
  if (highlight_best) {
    min_prices <- aggregate(price ~ origin, data = plot_data, FUN = min)
    names(min_prices) <- c("origin", "min_price")
    plot_data <- merge(plot_data, min_prices, by = "origin", all.x = TRUE)
    plot_data$is_min <- plot_data$price == plot_data$min_price
  } else {
    plot_data$is_min <- FALSE
  }
  
  # Define colorblind-friendly palette
  # Using a palette similar to Okabe-Ito or viridis
  color_palette <- c(
    "#E69F00", # Orange
    "#56B4E9", # Sky Blue
    "#009E73", # Bluish Green
    "#F0E442", # Yellow
    "#0072B2", # Blue
    "#D55E00", # Vermillion
    "#CC79A7", # Reddish Purple
    "#999999"  # Gray
  )
  
  # Create subtitle if not provided
  if (is.null(subtitle)) {
    min_origin <- plot_data$origin[which.min(plot_data$price)]
    min_price <- min(plot_data$price)
    subtitle <- sprintf(
      "Lowest price: $%d from %s",
      round(min_price),
      min_origin
    )
  }
  
  # Create the plot
  p <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = date, y = price, color = origin_label, group = origin_label)
  ) +
    ggplot2::geom_line(linewidth = 1.2) +
    ggplot2::geom_point(
      ggplot2::aes(size = is_min),
      show.legend = FALSE
    ) +
    ggplot2::scale_size_manual(values = c("FALSE" = 2, "TRUE" = 4)) +
    ggplot2::scale_color_manual(values = color_palette) +
    ggplot2::scale_y_continuous(
      labels = scales::dollar_format(),
      expand = ggplot2::expansion(mult = c(0.05, 0.1))
    ) +
    ggplot2::scale_x_date(
      date_labels = "%b %d",
      date_breaks = "1 day"
    ) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Departure Date",
      y = "Price (USD)",
      color = "Origin"
    ) +
    ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 16),
      plot.subtitle = ggplot2::element_text(color = "grey40", size = 11),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom",
      legend.title = ggplot2::element_text(face = "bold"),
      axis.title = ggplot2::element_text(face = "bold"),
      plot.margin = ggplot2::margin(10, 10, 10, 10)
    )
  
  return(p)
}
