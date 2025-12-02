#' Plot Best Travel Dates
#'
#' @description
#' Creates a modern visualization showing the best (cheapest) travel dates identified by
#' \code{\link{fa_find_best_dates}}. Uses a lollipop chart style that clearly shows
#' the price range and highlights the best options by origin and date.
#'
#' Uses ggplot2 for a polished, publication-ready aesthetic with colorblind-friendly
#' colors and clear typography.
#'
#' @param flight_results A flight_results object from [fa_fetch_flights()].
#' @param title Character. Plot title. Default is "Best Travel Dates by Price".
#' @param subtitle Character. Plot subtitle. Default is NULL (auto-generated).
#' @param x_axis_angle Numeric. Angle in degrees to rotate x-axis labels for better
#'   readability in wide figures with many dates. Common values are 45 (diagonal) or
#'   90 (vertical). Default is 0 (horizontal labels).
#' @param ... Additional arguments passed to \code{\link{fa_find_best_dates}}
#'   if best_dates is a flight_results object, including \code{excluded_airports}
#'   to filter out specific airport codes.
#'
#' @return A ggplot2 plot object that can be further customized or saved.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Plot best dates
#' fa_plot_best_dates(sample_flight_results, n = 5)
#'
#' # With filters
#' fa_plot_best_dates(sample_flight_results, n = 5, max_stops = 0)
#'
#' # Tilt x-axis labels diagonally for wide figures
#' fa_plot_best_dates(sample_flight_results, n = 10, x_axis_angle = 45)
#' }
fa_plot_best_dates <- function(
  flight_results,
  title = "Best Travel Dates by Price",
  subtitle = NULL,
  x_axis_angle = 0,
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

  # Validate input type - only accept flight_results objects
  if (!inherits(flight_results, "flight_results")) {
    stop(
      "flight_results must be a flight_results object from fa_fetch_flights().\n",
      "Please use fa_fetch_flights() to create a flight_results object first."
    )
  }

  # Extract data from flight_results object
  if (is.null(flight_results$data) || nrow(flight_results$data) == 0) {
    stop("No data to plot after filtering")
  }

  # Prepare data for plotting
  plot_data <- flight_results$data

  # Create date labels
  if ("departure_date" %in% names(plot_data)) {
    plot_data$date_label <- format(as.Date(plot_data$departure_date), "%b %d")
    if ("departure_time" %in% names(plot_data)) {
      plot_data$date_label <- paste0(
        plot_data$date_label,
        "\n",
        plot_data$departure_time
      )
    }
  } else if ("date" %in% names(plot_data)) {
    plot_data$date_label <- format(as.Date(plot_data$date), "%b %d")
  } else {
    plot_data$date_label <- as.character(seq_len(nrow(plot_data)))
  }

  # Add origin label if available
  has_origin <- "origin" %in% names(plot_data)
  if (has_origin) {
    plot_data$origin_label <- plot_data$origin
  } else {
    plot_data$origin_label <- "All"
  }

  # Sort by price for better visualization
  plot_data <- plot_data[order(plot_data$price), ]
  plot_data$rank <- seq_len(nrow(plot_data))

  # Define colorblind-friendly palette
  color_palette <- c(
    "#E69F00", # Orange
    "#56B4E9", # Sky Blue
    "#009E73", # Bluish Green
    "#F0E442", # Yellow
    "#0072B2", # Blue
    "#D55E00", # Vermillion
    "#CC79A7", # Reddish Purple
    "#999999" # Gray
  )

  # Create subtitle if not provided
  if (is.null(subtitle)) {
    min_price <- min(plot_data$price)
    max_price <- max(plot_data$price)
    subtitle <- sprintf(
      "Price range: $%d - $%d across top options",
      round(min_price),
      round(max_price)
    )
  }

  # Create lollipop chart
  # Note: Using variables rank, price, origin_label for NSE in ggplot2
  p <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = rank, y = price, color = origin_label)
  ) +
    ggplot2::geom_segment(
      ggplot2::aes(x = rank, xend = rank, y = 0, yend = price),
      linewidth = 2.5,
      alpha = 0.8
    ) +
    ggplot2::geom_point(size = 7) +
    ggplot2::geom_text(
      ggplot2::aes(label = scales::label_dollar()(price)),
      vjust = -1,
      size = 3.5,
      fontface = "bold",
      show.legend = FALSE
    ) +
    ggplot2::scale_color_manual(values = color_palette) +
    ggplot2::scale_y_continuous(
      labels = scales::dollar_format(),
      expand = ggplot2::expansion(mult = c(0, 0.15))
    ) +
    ggplot2::scale_x_continuous(
      breaks = plot_data$rank,
      labels = plot_data$date_label
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
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom",
      legend.title = ggplot2::element_text(face = "bold"),
      axis.title = ggplot2::element_text(face = "bold"),
      axis.text.x = ggplot2::element_text(
        angle = x_axis_angle,
        hjust = if (x_axis_angle > 0) 1 else 0.5,
        vjust = if (x_axis_angle >= 90) 0.5 else 1,
        size = 9
      ),
      plot.margin = ggplot2::margin(10, 10, 10, 10)
    )

  # Hide legend if only one origin
  if (!has_origin || length(unique(plot_data$origin_label)) == 1) {
    p <- p + ggplot2::theme(legend.position = "none")
  }

  return(p)
}
