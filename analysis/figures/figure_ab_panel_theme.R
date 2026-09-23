# Shared ggplot theme for side-by-side A/B manuscript panels (PIT, TwoStep, etc.)

figure_ab_panel_theme <- function(legend.position = "bottom") {
  theme_classic(base_size = 14) +
    theme(
      axis.title = element_text(size = 14, face = "bold"),
      axis.text = element_text(size = 11),
      strip.text = element_text(size = 11, face = "bold"),
      strip.background = element_rect(fill = "grey95", color = "grey30"),
      strip.placement = "outside",
      legend.position = legend.position,
      legend.box = "horizontal",
      legend.title = element_text(size = 11, face = "bold"),
      legend.text = element_text(size = 10),
      plot.margin = ggplot2::margin(5.5, 8, 5.5, 8)
    )
}

combine_ab_panels <- function(p_a, p_b, widths = c(1.35, 1.0)) {
  tag_theme <- theme(plot.tag = element_text(size = 16, face = "bold", hjust = 0, vjust = 1))
  (p_a + p_b +
    patchwork::plot_layout(widths = widths) +
    patchwork::plot_annotation(tag_levels = "A", theme = tag_theme)) &
    figure_ab_panel_theme(legend.position = "bottom")
}
