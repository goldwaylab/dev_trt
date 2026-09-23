p_to_star <- function(p) {
  if (!is.finite(p)) return("ns")
  if (p < 0.001) return("***")
  if (p < 0.01) return("**")
  if (p < 0.05) return("*")
  "ns"
}

session_paired_sig_annot <- function(bias_sub, pad_frac = 0.06, tick_frac = 0.025) {
  bias_wide <- bias_sub %>%
    dplyr::select(subject, age_group, session, pav_bias) %>%
    tidyr::pivot_wider(names_from = session, values_from = pav_bias) %>%
    dplyr::filter(!is.na(session_1), !is.na(session_2))

  sig_tests <- bias_wide %>%
    dplyr::group_by(age_group) %>%
    dplyr::summarise(
      n = dplyr::n(),
      p = suppressWarnings(tryCatch(
        stats::t.test(session_1, session_2, paired = TRUE)$p.value,
        error = function(e) NA_real_
      )),
      .groups = "drop"
    ) %>%
    dplyr::mutate(star = vapply(p, p_to_star, character(1)))

  mean_se_tbl <- bias_sub %>%
    dplyr::group_by(age_group, session) %>%
    dplyr::summarise(
      m = mean(pav_bias, na.rm = TRUE),
      se = sd(pav_bias, na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    )

  y_tbl <- mean_se_tbl %>%
    dplyr::group_by(age_group) %>%
    dplyr::summarise(y_top = max(m + se, na.rm = TRUE), .groups = "drop")

  span <- diff(range(bias_sub$pav_bias, na.rm = TRUE))
  if (!is.finite(span) || span <= 0) span <- 0.1
  pad <- pad_frac * span
  tick <- tick_frac * span

  sig_annot <- y_tbl %>%
    dplyr::left_join(sig_tests, by = "age_group") %>%
    dplyr::mutate(
      xmin = 1,
      xmax = 2,
      y = y_top + pad,
      y_lab = y_top + pad + tick * 0.8,
      y_tick = y - tick
    ) %>%
    dplyr::filter(star != "ns")

  list(tests = sig_tests, annot = sig_annot)
}

add_session_sig_brackets <- function(p, sig_obj) {
  ann <- sig_obj$annot
  if (nrow(ann) == 0) return(p)
  p +
    ggplot2::geom_segment(
      data = ann,
      ggplot2::aes(x = xmin, xend = xmax, y = y, yend = y),
      inherit.aes = FALSE,
      color = "black",
      linewidth = 0.35
    ) +
    ggplot2::geom_segment(
      data = ann,
      ggplot2::aes(x = xmin, xend = xmin, y = y_tick, yend = y),
      inherit.aes = FALSE,
      color = "black",
      linewidth = 0.35
    ) +
    ggplot2::geom_segment(
      data = ann,
      ggplot2::aes(x = xmax, xend = xmax, y = y_tick, yend = y),
      inherit.aes = FALSE,
      color = "black",
      linewidth = 0.35
    ) +
    ggplot2::geom_text(
      data = ann,
      ggplot2::aes(x = 1.5, y = y_lab, label = star),
      inherit.aes = FALSE,
      size = 4.2,
      fontface = "bold"
    )
}
