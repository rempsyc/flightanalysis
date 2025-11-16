#' Plot Price Summary
#'
#' @description
#' Creates a modern line plot showing price trends across dates for different origins/cities.
#' This visualizes the output from \code{\link{fa_summarize_prices}}, making it easy
#' to compare prices across dates and identify the best travel dates visually.
#' Point sizes vary inversely with price (cheaper flights = bigger points).
#'
#' Uses ggplot2 for a polished, publication-ready aesthetic with colorblind-friendly
#' colors and clear typography.
#'
#' @param price_summary A data frame from \code{\link{fa_summarize_prices}} or
#'   flight results that can be passed to \code{\link{fa_summarize_prices}}.
#' @param title Character. Plot title. Default is "Flight Prices by Date".
#' @param subtitle Character. Plot subtitle. Default is NULL (auto-generated).
#' @param annotate_col Character. Name of column from raw flight data to use for
#'   point annotations (e.g., "travel_time", "num_stops"). Only works when passing
#'   raw flight data, not summary tables. Default is NULL (no annotations).
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
#' # With custom title and annotations
#' fa_plot_prices(sample_flights,
#'                title = "Flight Prices: BOM/DEL to JFK",
#'                annotate_col = "travel_time")
#' }
fa_plot_prices <- function(
  price_summary,
  title = "Flight Prices by Date",
  subtitle = NULL,
  annotate_col = NULL,
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

  # Store raw data for annotations if provided
  raw_data <- NULL
  has_annotations <- !is.null(annotate_col)

  # If not already a summary table, create it
  if (!all(c("City", "Origin") %in% names(price_summary))) {
    # Keep raw data for annotations if requested
    if (has_annotations) {
      # Store the raw data before summarizing
      raw_data <- price_summary$data
    }
    price_summary <- fa_summarize_prices(price_summary, ...)
  }

  # Remove the "Best" row if present
  price_summary <- price_summary[price_summary$City != "Best", ]

  if (nrow(price_summary) == 0) {
    stop("No data to plot after filtering")
  }

  # Identify date columns (format YYYY-MM-DD)
  date_cols <- grep(
    "^[0-9]{4}-[0-9]{2}-[0-9]{2}$",
    names(price_summary),
    value = TRUE
  )

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
    origin_label <- paste0(
      price_summary$City[i],
      " (",
      price_summary$Origin[i],
      ")"
    )
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

  # Add annotation data if available
  if (
    has_annotations &&
      !is.null(raw_data) &&
      annotate_col %in% names(raw_data)
  ) {
    # Prepare date column for merging
    if (!("date" %in% names(raw_data))) {
      if ("departure_date" %in% names(raw_data)) {
        raw_data$date <- as.Date(raw_data$departure_date)
      } else if ("Date" %in% names(raw_data)) {
        raw_data$date <- as.Date(raw_data$Date)
      }
    } else {
      raw_data$date <- as.Date(raw_data$date)
    }

    # Prepare origin column for merging
    if (!("origin" %in% names(raw_data))) {
      if ("Airport" %in% names(raw_data)) {
        raw_data$origin <- raw_data$Airport
      } else if ("Origin" %in% names(raw_data)) {
        raw_data$origin <- raw_data$Origin
      } else if ("City" %in% names(raw_data)) {
        # Fallback: use City if no origin columns
        raw_data$origin <- raw_data$City
      }
    }

    # Ensure price column exists
    if (!("price" %in% names(raw_data))) {
      if ("Price" %in% names(raw_data)) {
        raw_data$price <- raw_data$Price
      }
    }

    # Get annotation value for the cheapest flight on each date-origin combo
    if (
      "date" %in%
        names(raw_data) &&
        "origin" %in% names(raw_data) &&
        "price" %in% names(raw_data)
    ) {
      # Select only needed columns
      annot_data <- raw_data[,
        c("date", "origin", "price", annotate_col),
        drop = FALSE
      ]

      # Get the row with minimum price for each date-origin combo
      annot_data <- do.call(
        rbind,
        lapply(
          split(annot_data, paste(annot_data$date, annot_data$origin)),
          function(x) {
            x[which.min(x$price), ]
          }
        )
      )

      # Create a version with just the annotation for merging
      annot_merge <- annot_data[,
        c("date", "origin", annotate_col),
        drop = FALSE
      ]

      # Ensure both date columns are the same class
      annot_merge$date <- as.Date(annot_merge$date)
      plot_data$date <- as.Date(plot_data$date)

      # Simplify annotation labels (e.g., "20 hr 15 min" -> "20h")
      # Create simplified version for display
      annot_merge$annot_display <- sapply(annot_merge[[annotate_col]], function(x) {
        if (is.na(x)) return(NA)
        x_str <- as.character(x)
        # Extract first number (assumes format like "20 hr" or "20 hr 15 min" or just "0")
        # For travel_time, extract hours
        if (grepl("hr", x_str, ignore.case = TRUE)) {
          # Extract the hour value
          hour_val <- gsub("^.*?(\\d+)\\s*hr.*$", "\\1", x_str, ignore.case = TRUE)
          return(paste0(hour_val, "h"))
        }
        # For numeric values (like num_stops), just return as-is
        return(x_str)
      })
      
      # Merge annotations into plot_data
      plot_data <- merge(
        plot_data,
        annot_merge,
        by = c("date", "origin"),
        all.x = TRUE
      )
    }
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
    "#999999" # Gray
  )

  # Create subtitle if not provided
  if (is.null(subtitle)) {
    min_idx <- which.min(plot_data$price)
    min_origin <- plot_data$origin[min_idx]
    min_price <- plot_data$price[min_idx]
    min_date <- plot_data$date[min_idx]
    subtitle <- sprintf(
      "Lowest price: $%d from %s on %s",
      round(min_price),
      min_origin,
      format(min_date, "%b %d")
    )
  }

  # Create the plot
  # Note: Using variables date, price, origin_label for NSE in ggplot2
  p <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = date,
      y = price,
      color = origin_label,
      group = origin_label
    )
  ) +
    ggplot2::geom_line(linewidth = 2) +
    ggplot2::geom_point(
      ggplot2::aes(size = price),
      shape = 21, # Circle with border and fill
      fill = "white", # White fill for all points
      stroke = 2, # Thicker border
      show.legend = FALSE
    ) +
    # Size varies inversely with price: cheaper = bigger
    ggplot2::scale_size_continuous(
      range = c(2, 8), # Min size for max price, max size for min price
      trans = "reverse"
    ) +
    ggplot2::scale_color_manual(values = color_palette) +
    ggplot2::scale_y_continuous(
      labels = scales::dollar_format(),
      expand = ggplot2::expansion(mult = c(0.05, 0.15))
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

  # Add annotations if requested and available
  if (has_annotations && "annot_display" %in% names(plot_data)) {
    # Check if ggrepel is available
    if (requireNamespace("ggrepel", quietly = TRUE)) {
      # Use ggrepel for non-overlapping labels
      # Calculate label size based on point size (price)
      # Normalize price to size range for labels: smaller for expensive, larger for cheap
      price_range <- range(plot_data$price, na.rm = TRUE)
      # Map price inversely to label size (2-4 range)
      plot_data$label_size <- 4 - 2 * (plot_data$price - price_range[1]) / 
        (price_range[2] - price_range[1])
      
      # Create a new ggplot with updated data that includes label_size
      p <- ggplot2::ggplot(
        plot_data,
        ggplot2::aes(
          x = date,
          y = price,
          color = origin_label,
          group = origin_label
        )
      ) +
        ggplot2::geom_line(linewidth = 2) +
        ggplot2::geom_point(
          ggplot2::aes(size = price),
          shape = 21,
          fill = "white",
          stroke = 2,
          show.legend = FALSE
        ) +
        ggplot2::scale_size_continuous(
          range = c(2, 8),
          trans = "reverse"
        ) +
        ggplot2::scale_color_manual(values = color_palette) +
        ggplot2::scale_y_continuous(
          labels = scales::dollar_format(),
          expand = ggplot2::expansion(mult = c(0.05, 0.15))
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
        ) +
        ggrepel::geom_text_repel(
          ggplot2::aes(label = annot_display),
          size = 3.5,  # Fixed base size
          fontface = "bold",
          show.legend = FALSE,
          color = "black",
          bg.color = "white",
          bg.r = 0.15,
          min.segment.length = 0,
          box.padding = 0.3,
          point.padding = 0.2,
          force = 3,
          max.overlaps = Inf
        )
    } else {
      # Fallback to geom_text if ggrepel not available
      p <- p +
        ggplot2::geom_text(
          ggplot2::aes(label = annot_display),
          size = 3,
          fontface = "bold",
          vjust = -1.5,
          show.legend = FALSE,
          color = "black"
        )
    }
  }

  return(p)
}
