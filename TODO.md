# TODO LIST

## Breaking Changes for Next PR

Make all data processing functions only work with `flight_results` objects (no backward compatibility):

- [ ] **fa_summarize_prices**: Remove support for direct data frame input
  - Keep only `flight_results` object handling
  - Remove `else if (is.data.frame(flight_results))` branch
  - Update documentation to reflect flight_results-only support
  
- [ ] **fa_plot_prices**: Remove support for pre-summarized data
  - Require `flight_results` objects only
  - Remove backward compatibility code for direct data frame/list input
  - Update documentation and parameter description
  
- [ ] **fa_find_best_dates**: Remove support for direct data frame input
  - Keep only `flight_results` object handling
  - Update documentation
  
- [ ] **Update all examples**: 
  - Replace `sample_flights` usage with `sample_flight_results` where applicable
  - Update vignettes if any exist
  
- [ ] **Update tests**: 
  - Add tests for flight_results-only validation
  - Add clear error messages when incorrect input types are provided
  
- [ ] **Documentation updates**:
  - Update README with flight_results-only workflow
  - Add migration guide for users upgrading from old version
  - Clarify that `sample_flights` is kept for demonstration but main functions require `flight_results`

**Note**: This is a BREAKING CHANGE - bump to version 3.0.0


