options(repos = c(CRAN = "https://cloud.r-project.org"))

required_packages <- c("readxl", "lmtest", "sandwich", "stargazer", "tseries")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  install.packages(missing_packages, quiet = TRUE)
}

suppressPackageStartupMessages({
  library(readxl)
  library(lmtest)
  library(sandwich)
  library(stargazer)
  library(tseries)
})

dir.create("tables", showWarnings = FALSE)

df <- read_excel("Data-t=1.xlsx")

work <- data.frame(
  y = df$`ln(Tourist)`,
  lag_y = df$`ln(Tourist-1)`,
  fx = df$`d_ln(FX)`,
  fx_l1 = df$`d_ln(FX-1)`,
  fx_l2 = df$`d_ln(FX-2)`,
  jipi = df$`ln(JIPI)`,
  jipi_l1 = df$`ln(JIPI-1)`,
  jipi_l2 = df$`ln(JIPI-2)`,
  oil = df$`d_ln(OilPrice)`,
  oil_l1 = df$`d_ln(OilPrice-1)`,
  oil_l2 = df$`d_ln(OilPrice-2)`,
  trend = df$t,
  month1 = df$Month1,
  month2 = df$Month2,
  month3 = df$Month3,
  month4 = df$Month4,
  month5 = df$Month5,
  month6 = df$Month6,
  month7 = df$Month7,
  month8 = df$Month8,
  month9 = df$Month9,
  month10 = df$Month10,
  month11 = df$Month11
)

model01 <- lm(
  y ~ fx + jipi + oil + trend +
    month1 + month2 + month3 + month4 + month5 + month6 +
    month7 + month8 + month9 + month10 + month11,
  data = work
)

model02 <- lm(
  y ~ lag_y + fx + fx_l1 + fx_l2 +
    jipi + jipi_l1 + jipi_l2 +
    oil + oil_l1 + oil_l2 + trend +
    month1 + month2 + month3 + month4 + month5 + month6 +
    month7 + month8 + month9 + month10 + month11,
  data = work
)

robust_vcov_01 <- vcovHAC(model01)
robust_vcov_02 <- vcovHAC(model02)

robust_se_01 <- sqrt(diag(robust_vcov_01))
robust_se_02 <- sqrt(diag(robust_vcov_02))

robust_ct_01 <- coeftest(model01, vcov. = robust_vcov_01)
robust_ct_02 <- coeftest(model02, vcov. = robust_vcov_02)

bg01 <- bgtest(model01, order = 1)
bg02 <- bgtest(model02, order = 1)

vif_lm <- function(model) {
  X <- model.matrix(model)
  X <- X[, colnames(X) != "(Intercept)", drop = FALSE]
  out <- numeric(ncol(X))
  names(out) <- colnames(X)
  for (i in seq_len(ncol(X))) {
    y <- X[, i]
    others <- X[, -i, drop = FALSE]
    if (ncol(others) == 0) {
      out[i] <- 1
    } else {
      fit <- lm(y ~ others)
      r2 <- summary(fit)$r.squared
      out[i] <- 1 / (1 - r2)
    }
  }
  out
}

max_vif_01 <- max(vif_lm(model01))
max_vif_02 <- max(vif_lm(model02))

fmt_num <- function(x, digits = 3) {
  formatC(x, format = "f", digits = digits)
}

fmt_p <- function(x) {
  if (x < 0.0001) {
    return(formatC(x, format = "e", digits = 2))
  }
  formatC(x, format = "f", digits = 4)
}

write_lines <- function(path, lines) {
  writeLines(lines, con = path, useBytes = TRUE)
}

coef_value <- function(ct, name, column = 1) {
  ct[name, column, drop = TRUE]
}

write_macro_file <- function() {
  lines <- c(
    paste0("\\newcommand{\\ModelOneRSq}{", fmt_num(summary(model01)$r.squared, 3), "}"),
    paste0("\\newcommand{\\ModelTwoRSq}{", fmt_num(summary(model02)$r.squared, 3), "}"),
    paste0("\\newcommand{\\LaggedArrivalCoef}{", fmt_num(coef_value(robust_ct_02, "lag_y", 1), 3), "}"),
    paste0("\\newcommand{\\LaggedArrivalP}{", fmt_p(coef_value(robust_ct_02, "lag_y", 4)), "}"),
    paste0("\\newcommand{\\FxCoefTwo}{", fmt_num(coef_value(robust_ct_02, "fx", 1), 3), "}"),
    paste0("\\newcommand{\\FxPTwo}{", fmt_p(coef_value(robust_ct_02, "fx", 4)), "}"),
    paste0("\\newcommand{\\JipiCoefTwo}{", fmt_num(coef_value(robust_ct_02, "jipi", 1), 3), "}"),
    paste0("\\newcommand{\\JipiPTwo}{", fmt_p(coef_value(robust_ct_02, "jipi", 4)), "}"),
    paste0("\\newcommand{\\OilCoefOne}{", fmt_num(coef_value(robust_ct_01, "oil", 1), 3), "}"),
    paste0("\\newcommand{\\OilPOne}{", fmt_p(coef_value(robust_ct_01, "oil", 4)), "}")
  )
  write_lines("tables/report_macros.tex", lines)
}

write_summary_table <- function() {
  desc <- data.frame(
    Variable = c("$\\ln(\\text{Tourist})$", "$\\Delta \\ln(\\text{FX})$", "$\\ln(\\text{JIPI})$", "$\\Delta \\ln(\\text{OilPrice})$"),
    Mean = c(mean(df$`ln(Tourist)`), mean(df$`d_ln(FX)`), mean(df$`ln(JIPI)`), mean(df$`d_ln(OilPrice)`)),
    `Std. Dev.` = c(sd(df$`ln(Tourist)`), sd(df$`d_ln(FX)`), sd(df$`ln(JIPI)`), sd(df$`d_ln(OilPrice)`)),
    Min = c(min(df$`ln(Tourist)`), min(df$`d_ln(FX)`), min(df$`ln(JIPI)`), min(df$`d_ln(OilPrice)`)),
    Max = c(max(df$`ln(Tourist)`), max(df$`d_ln(FX)`), max(df$`ln(JIPI)`), max(df$`d_ln(OilPrice)`))
  )

  lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Descriptive statistics for the core variables (generated in R)}",
    "\\begin{tabular}{lrrrr}",
    "\\toprule",
    "Variable & Mean & Std. Dev. & Min & Max \\\\",
    "\\midrule"
  )

  for (i in seq_len(nrow(desc))) {
    lines <- c(
      lines,
      paste0(
        desc$Variable[i], " & ",
        fmt_num(desc$Mean[i], 4), " & ",
        fmt_num(desc$`Std. Dev.`[i], 4), " & ",
        fmt_num(desc$Min[i], 4), " & ",
        fmt_num(desc$Max[i], 4), " \\\\"
      )
    )
  }

  lines <- c(lines, "\\bottomrule", "\\end{tabular}", "\\end{table}")
  write_lines("tables/summary_stats.tex", lines)
}

write_adf_table <- function() {
  adf_specs <- list(
    list(name = "$\\ln(\\text{Tourist})$", x = df$`ln(Tourist)`),
    list(name = "$\\Delta \\ln(\\text{FX})$", x = df$`d_ln(FX)`),
    list(name = "$\\ln(\\text{JIPI})$", x = df$`ln(JIPI)`),
    list(name = "$\\Delta \\ln(\\text{OilPrice})$", x = df$`d_ln(OilPrice)`)
  )

  rows <- lapply(adf_specs, function(spec) {
    test <- adf.test(spec$x)
    inference <- if (test$p.value < 0.05) {
      "Stationary at 5\\%"
    } else if (test$p.value < 0.10) {
      "Borderline; stationary at 10\\%"
    } else {
      "Non-stationary"
    }
    list(
      name = spec$name,
      stat = fmt_num(unname(test$statistic), 4),
      p = fmt_p(test$p.value),
      k = as.character(unname(test$parameter)),
      inference = inference
    )
  })

  lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Augmented Dickey-Fuller unit-root tests (generated in R)}",
    "\\begin{tabular}{lrrrl}",
    "\\toprule",
    "Variable & ADF statistic & p-value & Lags & Inference \\\\",
    "\\midrule"
  )

  for (row in rows) {
    lines <- c(
      lines,
      paste0(row$name, " & ", row$stat, " & ", row$p, " & ", row$k, " & ", row$inference, " \\\\")
    )
  }

  lines <- c(lines, "\\bottomrule", "\\end{tabular}", "\\end{table}")
  write_lines("tables/adf_table.tex", lines)
}

write_regression_table <- function() {
  invisible(capture.output(
    stargazer(
      model01, model02,
      type = "latex",
      out = "tables/regression_table_stata.tex",
      title = "Regression results with HAC standard errors (R-generated STATA-style table)",
      dep.var.caption = "Dependent variable:",
      dep.var.labels = c("$\\ln(\\text{Tourist})$"),
      column.labels = c("Model 1: Static", "Model 2: Dynamic"),
      model.numbers = FALSE,
      se = list(robust_se_01, robust_se_02),
      omit = "month",
      covariate.labels = c(
        "Lagged tourist arrivals",
        "Current exchange-rate change",
        "Exchange-rate change ($t-1$)",
        "Exchange-rate change ($t-2$)",
        "Current Japanese industrial production",
        "Japanese industrial production ($t-1$)",
        "Japanese industrial production ($t-2$)",
        "Current oil-price change",
        "Oil-price change ($t-1$)",
        "Oil-price change ($t-2$)",
        "Time trend"
      ),
      keep.stat = c("n", "rsq", "adj.rsq"),
      add.lines = list(
        c("Month dummies", "Included", "Included"),
        c("Breusch-Godfrey p-value", fmt_p(bg01$p.value), fmt_p(bg02$p.value)),
        c("Max VIF (excluding constant)", fmt_num(max_vif_01, 2), fmt_num(max_vif_02, 2))
      ),
      notes = "HAC standard errors in parentheses.",
      notes.align = "l",
      no.space = TRUE,
      font.size = "small",
      header = FALSE,
      float = TRUE,
      table.placement = "H"
    )
  ))
}

write_macro_file()
write_summary_table()
write_adf_table()
write_regression_table()
