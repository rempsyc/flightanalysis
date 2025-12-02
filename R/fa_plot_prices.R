#' Plot Price Summary
#'
#' @description
#' Creates a modern line plot showing price trends across dates for different origins/cities.
#' Requires flight_results objects from \code{\link{fa_fetch_flights}}.
#' This function no longer accepts pre-summarized data or data frames.
#'
#' Uses ggplot2 for a polished, publication-ready aesthetic with colorblind-friendly
#' colors and clear typography.
#'
#' @importFrom stats aggregate median
#' @param flight_results A flight_results object from [fa_fetch_flights()].
#' @param title Character. Plot title. Default is NULL (auto-generated with flight context).
#' @param subtitle Character. Plot subtitle. Default is NULL (auto-generated with lowest price info).
#' @param size_by Character. Name of column from raw flight data to use for
#'   point sizing. Can be "price", a column name like "travel_time",
#'   or NULL for uniform sizing (default). When using a column name, only works when passing
#'   raw flight data, not summary tables. Default is NULL.
#' @param annotate_col Character. Name of column from raw flight data to use for
#'   point annotations (e.g., "travel_time", "num_stops"). Only works when passing
#'   raw flight data, not summary tables. Default is NULL (no annotations).
#' @param use_ggrepel Logical. If TRUE, uses ggrepel for non-overlapping label
#'   positioning (requires ggrepel package). If FALSE, labels are centered on points
#'   and may overlap when there are many data points. Default is TRUE.
#' @param show_max_annotation Logical. If TRUE, adds a data-journalism-style
#'   annotation for the maximum price with a horizontal bar and formatted price label.
#'   The annotation is subtle and clean (no arrows or boxes). Default is TRUE.
#' @param show_min_annotation Logical. If TRUE, adds a data-journalism-style
#'   annotation for the minimum price with a horizontal bar and formatted price label.
#'   The annotation is subtle and clean (no arrows or boxes). Default is FALSE.
#' @param x_axis_angle Numeric. Angle in degrees to rotate x-axis labels for better
#'   readability in wide figures with many dates. Common values are 45 (diagonal) or
#'   90 (vertical). Default is 0 (horizontal labels).
#' @param drop_empty_dates Logical. If TRUE, removes dates that have no flight data
#'   (all NA prices) from the plot. This is useful when querying multiple airports
#'   where some may not have data for certain dates. Default is TRUE.
#' @param ... Additional arguments passed to \code{\link{fa_summarize_prices}},
#'   including \code{excluded_airports} to filter out specific airport codes.
#'
#' @return A ggplot2 plot object that can be further customized or saved.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic plot with auto-generated title and subtitle
#' fa_plot_prices(sample_flight_results)
#'
#' # With point size based on travel time and annotations
#' fa_plot_prices(sample_flight_results,
#'                size_by = "travel_time",
#'                annotate_col = "num_stops")
#'
#' # Size by number of stops
#' fa_plot_prices(sample_flight_results,
#'                size_by = "num_stops")
#'
#' # With annotations centered on points (no ggrepel)
#' fa_plot_prices(sample_flight_results,
#'                size_by = "travel_time",
#'                annotate_col = "travel_time",
#'                use_ggrepel = FALSE)
#'
#' # Custom title and both price annotations
#' fa_plot_prices(sample_flight_results,
#'                title = "Custom Title",
#'                show_max_annotation = TRUE,
#'                show_min_annotation = TRUE)
#'
#' # Tilt x-axis labels diagonally for wide figures
#' fa_plot_prices(sample_flight_results, x_axis_angle = 45)
#'
#' # Default behavior: filter out dates with no flight data
#' # Set drop_empty_dates = FALSE to keep all dates including empty ones
#' fa_plot_prices(sample_flight_results, drop_empty_dates = FALSE)
#' }
fa_plot_prices <- function(
  flight_results,
  title = NULL,
  subtitle = NULL,
  size_by = NULL,
  annotate_col = NULL,
  use_ggrepel = TRUE,
  show_max_annotation = TRUE,
  show_min_annotation = FALSE,
  x_axis_angle = 0,
  drop_empty_dates = TRUE,
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

  # Store raw data for annotations or size_by if provided
  raw_data <- flight_results$data
  has_annotations <- !is.null(annotate_col)
  has_custom_size <- !is.null(size_by) && size_by != "price"

  # Create summary table from flight_results
  flight_results <- fa_summarize_prices(flight_results, ...)

  # Remove the "Best" row if present
  flight_results <- flight_results[flight_results$City != "Best", ]

  if (nrow(flight_results) == 0) {
    stop("No data to plot after filtering")
  }

  # Identify date columns (format YYYY-MM-DD)
  date_cols <- grep(
    "^[0-9]{4}-[0-9]{2}-[0-9]{2}$",
    names(flight_results),
    value = TRUE
  )

  if (length(date_cols) == 0) {
    stop("No date columns found in flight_results")
  }

  # Extract price values (remove currency symbols and convert to numeric)
  price_data <- flight_results[, date_cols, drop = FALSE]
  for (col in date_cols) {
    price_data[[col]] <- as.numeric(gsub("[^0-9.]", "", price_data[[col]]))
  }

  # Drop empty date columns if requested (dates where all origins have NA prices)
  if (drop_empty_dates) {
    # Find date columns that have at least one non-NA price
    # sapply returns TRUE for columns with at least one non-NA value
    non_empty_cols <- sapply(date_cols, function(col) {
      !all(is.na(price_data[[col]]))
    })
    date_cols <- date_cols[non_empty_cols]
    price_data <- price_data[, date_cols, drop = FALSE]

    if (length(date_cols) == 0) {
      stop(
        "No dates with price data found. ",
        "Try setting drop_empty_dates = FALSE to include all dates."
      )
    }
  }

  # Convert to long format for ggplot2
  plot_data <- data.frame()
  for (i in seq_len(nrow(flight_results))) {
    origin_label <- paste0(
      flight_results$City[i],
      " (",
      flight_results$Origin[i],
      ")"
    )
    for (j in seq_along(date_cols)) {
      plot_data <- rbind(
        plot_data,
        data.frame(
          date = as.Date(date_cols[j]),
          price = as.numeric(price_data[i, j]),
          origin = flight_results$Origin[i],
          origin_label = origin_label,
          stringsAsFactors = FALSE
        )
      )
    }
  }

  # Remove any NA prices
  plot_data <- plot_data[!is.na(plot_data$price), ]

  # Order plot_data explicitly for consistent line drawing
  # Lines are drawn in data order, so we order by date and origin for consistency
  plot_data <- plot_data[order(plot_data$date, plot_data$origin), ]

  # Add size_by data if using a custom column
  if (
    has_custom_size &&
      !is.null(raw_data) &&
      size_by %in% names(raw_data)
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

    # Get size_by value for the cheapest flight on each date-origin combo
    if (
      "date" %in%
        names(raw_data) &&
        "origin" %in% names(raw_data) &&
        "price" %in% names(raw_data)
    ) {
      # Select only needed columns
      size_data <- raw_data[,
        c("date", "origin", "price", size_by),
        drop = FALSE
      ]

      # Get the row with minimum price for each date-origin combo
      size_data <- do.call(
        rbind,
        lapply(
          split(size_data, paste(size_data$date, size_data$origin)),
          function(x) {
            x[which.min(x$price), ]
          }
        )
      )

      # Create a version with just the size_by value for merging
      size_merge <- size_data[,
        c("date", "origin", size_by),
        drop = FALSE
      ]
      names(size_merge)[3] <- "size_value"

      # Ensure both date columns are the same class
      size_merge$date <- as.Date(size_merge$date)

      # Merge size data into plot_data
      plot_data <- merge(
        plot_data,
        size_merge,
        by = c("date", "origin"),
        all.x = TRUE
      )

      # Re-order after merge
      plot_data <- plot_data[order(plot_data$date, plot_data$origin), ]
    }
  }

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
      annot_merge$annot_display <- sapply(
        annot_merge[[annotate_col]],
        function(x) {
          if (is.na(x)) {
            return(NA)
          }
          x_str <- as.character(x)
          # Extract first number (assumes format like "20 hr" or "20 hr 15 min" or just "0")
          # For travel_time, extract hours
          if (grepl("hr", x_str, ignore.case = TRUE)) {
            # Extract the hour value
            hour_val <- gsub(
              "^.*?(\\d+)\\s*hr.*$",
              "\\1",
              x_str,
              ignore.case = TRUE
            )
            return(paste0(hour_val, "h"))
          }
          # For numeric values (like num_stops), just return as-is
          return(x_str)
        }
      )

      # Merge annotations into plot_data
      plot_data <- merge(
        plot_data,
        annot_merge,
        by = c("date", "origin"),
        all.x = TRUE
      )

      # Re-order after merge
      plot_data <- plot_data[order(plot_data$date, plot_data$origin), ]
    }
  }

  # Compute point_size column based on size_by parameter
  # This will be used for both sizing and ordering (smaller points on top)
  if (!is.null(size_by)) {
    if (size_by == "price") {
      # For price: lower values get bigger points (inverse relationship)
      # We'll use the inverse when setting the scale
      plot_data$point_size <- plot_data$price
    } else if ("size_value" %in% names(plot_data)) {
      # For other columns: use the raw value
      # Special handling for travel_time format "XX hr YY min"
      if (
        size_by == "travel_time" || grepl("time", size_by, ignore.case = TRUE)
      ) {
        # Convert "16 hr 30 min" to total hours (16.5)
        plot_data$point_size <- sapply(plot_data$size_value, function(x) {
          if (is.na(x)) {
            return(NA)
          }
          x_str <- as.character(x)
          # Extract hours
          hours <- as.numeric(gsub(
            "^.*?(\\d+)\\s*hr.*$",
            "\\1",
            x_str,
            ignore.case = TRUE
          ))
          if (is.na(hours)) {
            hours <- 0
          }
          # Extract minutes if present
          if (grepl("min", x_str, ignore.case = TRUE)) {
            minutes <- as.numeric(gsub(
              "^.*?(\\d+)\\s*min.*$",
              "\\1",
              x_str,
              ignore.case = TRUE
            ))
            if (is.na(minutes)) {
              minutes <- 0
            }
            return(hours + minutes / 60)
          }
          return(hours)
        })
      } else {
        # Try to convert to numeric if possible
        plot_data$point_size <- suppressWarnings(as.numeric(
          plot_data$size_value
        ))
        # If conversion fails, use rank
        if (all(is.na(plot_data$point_size))) {
          plot_data$point_size <- as.numeric(as.factor(plot_data$size_value))
        }
      }
    } else {
      # Fallback: use price
      plot_data$point_size <- plot_data$price
    }
  } else {
    # Uniform sizing if size_by is NULL
    plot_data$point_size <- 1
  }

  # Reorder origin factor based on size_by metric for better line stacking
  # This ensures lines are drawn in a semantically meaningful order
  if (!is.null(size_by) && "point_size" %in% names(plot_data)) {
    # Compute summary statistic per origin (median of point_size)
    origin_order <- aggregate(
      point_size ~ origin,
      data = plot_data,
      FUN = median,
      na.rm = TRUE
    )
    # Sort by the summary statistic (smaller values first for better visual order)
    origin_order <- origin_order[order(origin_order$point_size), ]

    # Reorder the origin factor in plot_data
    plot_data$origin <- factor(
      plot_data$origin,
      levels = origin_order$origin
    )

    # Also update origin_label to maintain the same order
    plot_data$origin_label <- factor(
      plot_data$origin_label,
      levels = unique(plot_data$origin_label[order(plot_data$origin)])
    )
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

  # Auto-generate title and subtitle if not provided
  # Title: Flight context (origins, destination, date range)
  # Subtitle: Lowest price information
  auto_title <- NULL
  auto_subtitle <- NULL

  # Extract unique origins
  origins_list <- unique(plot_data$origin)
  origins_str <- paste(origins_list, collapse = "/")

  # Try to extract destination from raw_data if available
  destination_str <- NULL
  if (!is.null(raw_data)) {
    if ("destination" %in% names(raw_data)) {
      dest <- unique(raw_data$destination)
      if (length(dest) > 0) destination_str <- paste(dest, collapse = "/")
    } else if ("Destination" %in% names(raw_data)) {
      dest <- unique(raw_data$Destination)
      if (length(dest) > 0) destination_str <- paste(dest, collapse = "/")
    }
  }

  # Get date range
  dates <- sort(unique(plot_data$date))
  if (length(dates) > 1) {
    date_range_str <- sprintf(
      "%s-%s",
      format(min(dates), "%b %d"),
      format(max(dates), "%b %d")
    )
  } else {
    date_range_str <- format(dates[1], "%b %d")
  }

  # Construct auto title (flight context)
  if (!is.null(destination_str)) {
    auto_title <- sprintf(
      "Cheapest Flight Prices for %s to %s over %s",
      origins_str,
      destination_str,
      date_range_str
    )
  } else {
    auto_title <- sprintf(
      "Cheapest Flight Prices from %s over %s",
      origins_str,
      date_range_str
    )
  }

  # Construct auto subtitle (lowest price info)
  min_idx <- which.min(plot_data$price)
  min_origin <- plot_data$origin[min_idx]
  min_price <- plot_data$price[min_idx]
  min_date <- plot_data$date[min_idx]
  auto_subtitle <- sprintf(
    "Lowest price: $%d from %s on %s",
    round(min_price),
    min_origin,
    format(min_date, "%b %d")
  )

  # Use provided title/subtitle or auto-generated ones
  if (is.null(title)) {
    title <- auto_title
  }
  if (is.null(subtitle)) {
    subtitle <- auto_subtitle
  }

  # Add annotation label info to subtitle if annotations are present
  # This is done after setting subtitle so it applies to both custom and auto-generated subtitles
  if (has_annotations) {
    annot_label <- gsub("_", " ", annotate_col)
    annot_label <- tools::toTitleCase(annot_label)
    subtitle <- sprintf(
      "%s (Point labels: %s)",
      subtitle,
      annot_label
    )
  }

  # Create the base plot with consistent data ordering
  # Lines: use plot_data ordered by date and origin (reordered above if size_by is set)
  # Points: will be drawn later with ordering by point_size

  # Draw lines first with explicitly ordered data by date and origin
  # If origin was reordered above, this will reflect that order
  line_data <- plot_data[order(plot_data$date, plot_data$origin), ]

  # For points: arrange so smaller points are drawn last (on top)
  # Use origin as secondary sort key to maintain consistency
  if (!is.null(size_by) && size_by == "price") {
    # For price: larger point_size (expensive) drawn first, smaller (cheap) drawn last (on top)
    point_data <- plot_data[order(-plot_data$point_size, plot_data$origin), ]
    size_trans <- "reverse" # Inverse relationship: high price = small point
    # Capitalize and clean up label
    size_label <- "Price"
  } else if (!is.null(size_by)) {
    # For other metrics: smaller point_size drawn last (on top)
    point_data <- plot_data[order(-plot_data$point_size, plot_data$origin), ]
    size_trans <- "identity" # Direct relationship
    # Capitalize and clean up label (e.g., "travel_time" -> "Travel Time")
    clean_name <- gsub("_", " ", size_by)
    clean_name <- tools::toTitleCase(clean_name)
    size_label <- clean_name
  } else {
    # Uniform sizing
    point_data <- plot_data
    size_trans <- "identity"
    size_label <- NULL
  }

  # Create the plot
  # Note: Using variables date, price, origin_label, point_size for NSE in ggplot2
  p <- ggplot2::ggplot(
    line_data,
    ggplot2::aes(
      x = date,
      y = price,
      color = origin_label,
      group = origin_label
    )
  ) +
    ggplot2::geom_line(linewidth = 2)

  # Add points with explicit data ordering
  if (!is.null(size_by)) {
    # Calculate min and max for legend breaks
    point_size_range <- range(plot_data$point_size, na.rm = TRUE)

    p <- p +
      ggplot2::geom_point(
        data = point_data,
        ggplot2::aes(size = point_size),
        shape = 21, # Circle with border and fill
        fill = "white", # White fill for all points
        stroke = 2, # Thicker border
        show.legend = TRUE # Show legend for size
      ) +
      ggplot2::scale_size_continuous(
        name = size_label,
        range = c(2, 7),
        trans = size_trans,
        breaks = point_size_range,
        labels = round(point_size_range),
        guide = ggplot2::guide_legend(
          override.aes = list(stroke = 1, fill = "white")
        )
      )
  } else {
    # Uniform size points
    p <- p +
      ggplot2::geom_point(
        data = point_data,
        size = 5,
        shape = 21,
        fill = "white",
        stroke = 2,
        show.legend = FALSE
      )
  }

  # Add remaining scales and theme
  p <- p +
    ggplot2::scale_color_manual(values = color_palette) +
    ggplot2::scale_y_continuous(
      labels = scales::dollar_format(),
      expand = ggplot2::expansion(mult = c(0.05, 0.15))
    ) +
    ggplot2::scale_x_date(
      date_labels = "%b %d",
      date_breaks = "1 day",
      limits = c(min(plot_data$date), max(plot_data$date))
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
      axis.text.x = ggplot2::element_text(
        angle = x_axis_angle,
        hjust = if (x_axis_angle > 0) 1 else 0.5,
        vjust = if (x_axis_angle >= 90) 0.5 else 1
      ),
      plot.margin = ggplot2::margin(10, 10, 10, 10)
    )

  # Add maximum price annotation if requested
  if (show_max_annotation) {
    # Find the row with maximum price
    max_idx <- which.max(plot_data$price)
    max_price <- plot_data$price[max_idx]
    max_date <- plot_data$date[max_idx]

    # Calculate data-dependent offsets
    price_range <- max(plot_data$price, na.rm = TRUE) -
      min(plot_data$price, na.rm = TRUE)

    # Vertical offset above the max point (about 8% of price range)
    bar_y_offset <- price_range * 0.08
    bar_y <- max_price + bar_y_offset

    # Label position (slightly above the bar)
    label_y_offset <- price_range * 0.04
    label_y <- bar_y + label_y_offset

    # Bar width in days (0.5 days on each side = 1 day total)
    bar_width <- 0.5
    bar_xmin <- max_date - bar_width
    bar_xmax <- max_date + bar_width

    # Format price for label (with comma separator)
    max_price_label <- scales::dollar_format()(max_price)

    # Add horizontal bar annotation (thin black line)
    p <- p +
      ggplot2::annotate(
        "segment",
        x = bar_xmin,
        xend = bar_xmax,
        y = bar_y,
        yend = bar_y,
        color = "black",
        linewidth = 0.8
      ) +
      # Add price label above the bar
      ggplot2::annotate(
        "text",
        x = max_date,
        y = label_y,
        label = max_price_label,
        fontface = "bold",
        size = 4,
        color = "black",
        vjust = 0
      )
  }

  # Add minimum price annotation if requested
  if (show_min_annotation) {
    # Find the row with minimum price
    min_idx <- which.min(plot_data$price)
    min_price <- plot_data$price[min_idx]
    min_date <- plot_data$date[min_idx]

    # Calculate data-dependent offsets
    price_range <- max(plot_data$price, na.rm = TRUE) -
      min(plot_data$price, na.rm = TRUE)

    # Vertical offset below the min point (about 8% of price range)
    bar_y_offset <- price_range * 0.08
    bar_y <- min_price - bar_y_offset

    # Label position (slightly below the bar)
    label_y_offset <- price_range * 0.04
    label_y <- bar_y - label_y_offset

    # Bar width in days (0.5 days on each side = 1 day total)
    bar_width <- 0.5
    bar_xmin <- min_date - bar_width
    bar_xmax <- min_date + bar_width

    # Format price for label (with comma separator)
    min_price_label <- scales::dollar_format()(min_price)

    # Add horizontal bar annotation (thin black line)
    p <- p +
      ggplot2::annotate(
        "segment",
        x = bar_xmin,
        xend = bar_xmax,
        y = bar_y,
        yend = bar_y,
        color = "black",
        linewidth = 0.8
      ) +
      # Add price label below the bar
      ggplot2::annotate(
        "text",
        x = min_date,
        y = label_y,
        label = min_price_label,
        fontface = "bold",
        size = 4,
        color = "black",
        vjust = 1
      )
  }

  # Add annotations if requested and available
  # This is added as a layer on top of the existing plot, avoiding duplication
  if (has_annotations && "annot_display" %in% names(plot_data)) {
    # Check if user wants ggrepel and if it's available
    if (use_ggrepel && requireNamespace("ggrepel", quietly = TRUE)) {
      # Use ggrepel for non-overlapping labels
      p <- p +
        ggrepel::geom_text_repel(
          ggplot2::aes(label = annot_display),
          size = 3.5, # Fixed base size
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
      # Use centered labels (no ggrepel) - labels may overlap
      # This is cleaner when there are lots of data points
      p <- p +
        ggplot2::geom_text(
          ggplot2::aes(label = annot_display),
          size = 3,
          fontface = "bold",
          vjust = 0.5, # Center vertically
          hjust = 0.5, # Center horizontally
          show.legend = FALSE,
          color = "black"
        )
    }
  }

  return(p)
}
