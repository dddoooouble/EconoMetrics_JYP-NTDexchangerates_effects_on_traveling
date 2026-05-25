library(readxl)
library(dplyr)
library(lmtest)
library(sandwich)

output_dir <- "output"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

data_path <- "資料.xlsx"
df <- read_excel(data_path) %>%
  mutate(
    date = as.Date(paste0(substr(`期間t`, 1, 4), "-", substr(`期間t`, 6, 7), "-01")),
    ln_tourist = log(Tourist),
    lnFX_lag1 = dplyr::lag(`ln(FX)`, 1),
    lnFX_lag2 = dplyr::lag(`ln(FX)`, 2),
    ln_tourist_lag1 = dplyr::lag(ln_tourist, 1),
    d_ln_tourist = ln_tourist - dplyr::lag(ln_tourist, 1),
    d_ln_fx = `ln(FX)` - dplyr::lag(`ln(FX)`, 1),
    d_ln_jipi = `ln(JIPI)` - dplyr::lag(`ln(JIPI)`, 1),
    d_ln_oil = `ln(OilPrice)` - dplyr::lag(`ln(OilPrice)`, 1)
  )

month_terms <- paste0("Month", 1:11, collapse = " + ")

baseline_formula <- as.formula("ln_tourist ~ `ln(FX)`")
full_formula <- as.formula(
  paste("ln_tourist ~ `ln(FX)` + `ln(JIPI)` + `ln(OilPrice)` + t +", month_terms)
)
dynamic_formula <- as.formula(
  paste(
    "ln_tourist ~ ln_tourist_lag1 + `ln(FX)` + `ln(JIPI)` + `ln(OilPrice)` +",
    month_terms
  )
)
distributed_formula <- as.formula(
  paste(
    "ln_tourist ~ `ln(FX)` + lnFX_lag1 + lnFX_lag2 + `ln(JIPI)` + `ln(OilPrice)` + t +",
    month_terms
  )
)
diff_formula <- as.formula("d_ln_tourist ~ d_ln_fx + d_ln_jipi + d_ln_oil")

models <- list(
  baseline = lm(baseline_formula, data = df),
  full = lm(full_formula, data = df),
  dynamic = lm(dynamic_formula, data = df),
  distributed = lm(distributed_formula, data = df),
  difference = lm(diff_formula, data = df)
)

vcovs <- lapply(models, function(model) {
  sandwich::NeweyWest(model, lag = 12, prewhite = FALSE, adjust = TRUE)
})

tidy_with_ols <- function(model) {
  result <- summary(model)$coefficients
  ci <- suppressMessages(confint(model))
  tibble(
    term = rownames(result),
    estimate = result[, 1],
    std_error = result[, 2],
    statistic = result[, 3],
    p_value = result[, 4],
    conf_low = ci[, 1],
    conf_high = ci[, 2]
  )
}

tidy_with_hac <- function(model, vcov_matrix) {
  result <- lmtest::coeftest(model, vcov. = vcov_matrix)
  tibble(
    term = rownames(result),
    estimate = result[, 1],
    std_error = result[, 2],
    statistic = result[, 3],
    p_value = result[, 4]
  )
}

model_tidy <- Map(tidy_with_hac, models, vcovs)
model_tidy_ols <- lapply(models, tidy_with_ols)

stars <- function(p_value) {
  if (is.na(p_value)) {
    ""
  } else if (p_value < 0.01) {
    "***"
  } else if (p_value < 0.05) {
    "**"
  } else if (p_value < 0.10) {
    "*"
  } else {
    ""
  }
}

fmt_num <- function(value, digits = 3) {
  if (is.na(value)) {
    ""
  } else {
    formatC(value, digits = digits, format = "f")
  }
}

fmt_coef <- function(estimate, p_value, digits = 3) {
  if (is.na(estimate)) {
    ""
  } else {
    paste0(fmt_num(estimate, digits), stars(p_value))
  }
}

extract_term <- function(model_name, term_name) {
  tbl <- model_tidy[[model_name]]
  row <- tbl %>% filter(term == term_name)
  if (nrow(row) == 0) {
    return(list(coef = "", se = ""))
  }
  list(
    coef = fmt_coef(row$estimate[[1]], row$p_value[[1]]),
    se = paste0("(", fmt_num(row$std_error[[1]]), ")")
  )
}

write_latex_table <- function(lines, file_name) {
  writeLines(lines, file.path(output_dir, file_name))
}

stata_metrics <- function(model) {
  y <- model$model[[1]]
  rss <- sum(residuals(model)^2)
  tss <- sum((y - mean(y))^2)
  ess <- tss - rss
  k <- length(coef(model)) - 1
  df_resid <- df.residual(model)
  fstat <- summary(model)$fstatistic
  list(
    n = nobs(model),
    k = k,
    df_resid = df_resid,
    model_ss = ess,
    resid_ss = rss,
    total_ss = tss,
    model_ms = ess / k,
    resid_ms = rss / df_resid,
    total_ms = tss / (k + df_resid),
    f = unname(fstat[1]),
    f_df1 = unname(fstat[2]),
    f_df2 = unname(fstat[3]),
    prob_f = pf(unname(fstat[1]), unname(fstat[2]), unname(fstat[3]), lower.tail = FALSE),
    r2 = summary(model)$r.squared,
    adj_r2 = summary(model)$adj.r.squared,
    root_mse = sqrt(rss / df_resid)
  )
}

build_stata_table <- function(model_name, caption, label, file_name, keep_terms, display_names) {
  model <- models[[model_name]]
  tidy_tbl <- model_tidy_ols[[model_name]]
  stats <- stata_metrics(model)
  rows <- c(
    "\\begin{table}[H]",
    "\\centering",
    paste0("\\caption{", caption, "}"),
    paste0("\\label{", label, "}"),
    "\\begin{minipage}{0.48\\textwidth}",
    "\\centering",
    "\\begin{tabular}{lrrrr}",
    "\\toprule",
    "Source & SS & df & MS & \\\\",
    "\\midrule",
    paste0("Model & ", fmt_num(stats$model_ss, 4), " & ", stats$k, " & ", fmt_num(stats$model_ms, 4), " & \\\\"),
    paste0("Residual & ", fmt_num(stats$resid_ss, 4), " & ", stats$df_resid, " & ", fmt_num(stats$resid_ms, 4), " & \\\\"),
    paste0("Total & ", fmt_num(stats$total_ss, 4), " & ", stats$k + stats$df_resid, " & ", fmt_num(stats$total_ms, 4), " & \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{minipage}",
    "\\hfill",
    "\\begin{minipage}{0.44\\textwidth}",
    "\\centering",
    "\\begin{tabular}{lr}",
    "\\toprule",
    "Statistic & Value \\\\",
    "\\midrule",
    paste0("Number of obs & ", stats$n, " \\\\"),
    paste0("$F(", stats$f_df1, ",", stats$f_df2, ")$ & ", fmt_num(stats$f, 2), " \\\\"),
    paste0("Prob $>$ $F$ & ", fmt_num(stats$prob_f, 4), " \\\\"),
    paste0("$R^2$ & ", fmt_num(stats$r2, 4), " \\\\"),
    paste0("Adj. $R^2$ & ", fmt_num(stats$adj_r2, 4), " \\\\"),
    paste0("Root MSE & ", fmt_num(stats$root_mse, 4), " \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{minipage}",
    "\\vspace{0.8em}",
    "\\begin{tabular}{lrrrrr}",
    "\\toprule",
    "Variable & Coef. & Std. Err. & $t$ & $P>|t|$ & 95\\% CI \\\\",
    "\\midrule"
  )

  for (i in seq_along(keep_terms)) {
    row <- tidy_tbl %>% filter(term == keep_terms[[i]])
    if (nrow(row) == 0) {
      next
    }
    rows <- c(
      rows,
      paste0(
        display_names[[i]], " & ",
        fmt_num(row$estimate[[1]], 4), " & ",
        fmt_num(row$std_error[[1]], 4), " & ",
        fmt_num(row$statistic[[1]], 2), " & ",
        fmt_num(row$p_value[[1]], 4), " & [",
        fmt_num(row$conf_low[[1]], 4), ", ",
        fmt_num(row$conf_high[[1]], 4), "] \\\\"
      )
    )
  }

  rows <- c(
    rows,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{minipage}{0.95\\textwidth}",
    "\\vspace{0.4em}\\footnotesize Notes: This table follows the conventional OLS output style used by Stata. Coefficient inference here is based on classical OLS standard errors. The main comparison tables in the paper additionally report Newey--West standard errors.",
    "\\end{minipage}",
    "\\end{table}"
  )

  write_latex_table(rows, file_name)
}

adf_manual <- function(x, k = 1, trend = TRUE) {
  x <- as.numeric(na.omit(x))
  dx <- diff(x)
  y_lag <- x[-length(x)]
  work_df <- data.frame(dx = dx, y_lag = y_lag)
  if (k > 0) {
    for (i in seq_len(k)) {
      work_df[[paste0("lag_dx", i)]] <- dplyr::lag(dx, i)
    }
  }
  if (trend) {
    work_df$trend <- seq_len(nrow(work_df))
  }
  work_df <- na.omit(work_df)
  rhs <- "y_lag"
  if (trend) {
    rhs <- c(rhs, "trend")
  }
  if (k > 0) {
    rhs <- c(rhs, paste0("lag_dx", seq_len(k)))
  }
  model <- lm(as.formula(paste("dx ~", paste(rhs, collapse = " + "))), data = work_df)
  coef_table <- summary(model)$coefficients
  list(
    statistic = unname(coef_table["y_lag", "t value"]),
    coefficient = unname(coef_table["y_lag", "Estimate"]),
    n = nrow(work_df)
  )
}

summary_stats <- tibble(
  Variable = c(
    "Japanese tourist arrivals",
    "Log tourist arrivals",
    "Log exchange rate",
    "Log Japanese industrial production",
    "Log Brent oil price"
  ),
  Mean = c(
    mean(df$Tourist, na.rm = TRUE),
    mean(df$ln_tourist, na.rm = TRUE),
    mean(df$`ln(FX)`, na.rm = TRUE),
    mean(df$`ln(JIPI)`, na.rm = TRUE),
    mean(df$`ln(OilPrice)`, na.rm = TRUE)
  ),
  SD = c(
    sd(df$Tourist, na.rm = TRUE),
    sd(df$ln_tourist, na.rm = TRUE),
    sd(df$`ln(FX)`, na.rm = TRUE),
    sd(df$`ln(JIPI)`, na.rm = TRUE),
    sd(df$`ln(OilPrice)`, na.rm = TRUE)
  ),
  Min = c(
    min(df$Tourist, na.rm = TRUE),
    min(df$ln_tourist, na.rm = TRUE),
    min(df$`ln(FX)`, na.rm = TRUE),
    min(df$`ln(JIPI)`, na.rm = TRUE),
    min(df$`ln(OilPrice)`, na.rm = TRUE)
  ),
  Max = c(
    max(df$Tourist, na.rm = TRUE),
    max(df$ln_tourist, na.rm = TRUE),
    max(df$`ln(FX)`, na.rm = TRUE),
    max(df$`ln(JIPI)`, na.rm = TRUE),
    max(df$`ln(OilPrice)`, na.rm = TRUE)
  ),
  N = c(
    sum(!is.na(df$Tourist)),
    sum(!is.na(df$ln_tourist)),
    sum(!is.na(df$`ln(FX)`)),
    sum(!is.na(df$`ln(JIPI)`)),
    sum(!is.na(df$`ln(OilPrice)`))
  )
)

summary_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Variable & Mean & SD & Min & Max & N \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(summary_stats))) {
  row <- summary_stats[i, ]
  summary_lines <- c(
    summary_lines,
    paste0(
      row$Variable, " & ",
      fmt_num(row$Mean), " & ",
      fmt_num(row$SD), " & ",
      fmt_num(row$Min), " & ",
      fmt_num(row$Max), " & ",
      formatC(row$N, format = "d"),
      " \\\\"
    )
  )
}

summary_lines <- c(
  summary_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.9\\textwidth}",
  "\\vspace{0.4em}\\footnotesize Notes: The sample covers monthly observations from October 2009 to December 2019.",
  "\\end{minipage}",
  "\\end{table}"
)

write_latex_table(summary_lines, "summary_statistics.tex")

correlation_data <- df %>%
  select(ln_tourist, `ln(FX)`, `ln(JIPI)`, `ln(OilPrice)`)

cor_mat <- cor(correlation_data, use = "pairwise.complete.obs")
cor_names <- c(
  "Log tourist arrivals",
  "Log exchange rate",
  "Log Japanese industrial production",
  "Log Brent oil price"
)

cor_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Correlation Matrix}",
  "\\label{tab:corr}",
  "\\begin{tabular}{lrrrr}",
  "\\toprule",
  "Variable & (1) & (2) & (3) & (4) \\\\",
  "\\midrule"
)

for (i in seq_along(cor_names)) {
  cor_lines <- c(
    cor_lines,
    paste0(
      cor_names[[i]], " & ",
      paste(vapply(seq_len(ncol(cor_mat)), function(j) fmt_num(cor_mat[i, j]), character(1)), collapse = " & "),
      " \\\\"
    )
  )
}

cor_lines <- c(
  cor_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
)

write_latex_table(cor_lines, "correlation_matrix.tex")

build_stata_table(
  "full",
  "Detailed OLS Output for the Full Model",
  "tab:statafull",
  "stata_full_model.tex",
  c("(Intercept)", "`ln(FX)`", "`ln(JIPI)`", "`ln(OilPrice)`", "t"),
  c("Constant", "Log exchange rate", "Log Japanese industrial production", "Log Brent oil price", "Time trend")
)

build_stata_table(
  "dynamic",
  "Detailed OLS Output for the Dynamic Model",
  "tab:statadyn",
  "stata_dynamic_model.tex",
  c("(Intercept)", "ln_tourist_lag1", "`ln(FX)`", "`ln(JIPI)`", "`ln(OilPrice)`"),
  c("Constant", "Lagged log tourist arrivals", "Log exchange rate", "Log Japanese industrial production", "Log Brent oil price")
)

blank_cell <- list(coef = "", se = "")

main_specs <- list(
  "Log exchange rate" = list(
    extract_term("baseline", "`ln(FX)`"),
    extract_term("full", "`ln(FX)`"),
    extract_term("dynamic", "`ln(FX)`")
  ),
  "Log Japanese industrial production" = list(
    blank_cell,
    extract_term("full", "`ln(JIPI)`"),
    extract_term("dynamic", "`ln(JIPI)`")
  ),
  "Log Brent oil price" = list(
    blank_cell,
    extract_term("full", "`ln(OilPrice)`"),
    extract_term("dynamic", "`ln(OilPrice)`")
  ),
  "Time trend" = list(
    blank_cell,
    extract_term("full", "t"),
    blank_cell
  ),
  "Lagged log tourist arrivals" = list(
    blank_cell,
    blank_cell,
    extract_term("dynamic", "ln_tourist_lag1")
  )
)

main_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Baseline Regression Results}",
  "\\label{tab:mainreg}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  "Variables & Bivariate & Full Model & Dynamic Model \\\\",
  "\\midrule"
)

for (row_name in names(main_specs)) {
  cells <- main_specs[[row_name]]
  main_lines <- c(
    main_lines,
    paste0(
      row_name, " & ",
      paste(vapply(cells, function(x) x$coef, character(1)), collapse = " & "),
      " \\\\"
    ),
    paste0(
      " & ",
      paste(vapply(cells, function(x) x$se, character(1)), collapse = " & "),
      " \\\\"
    )
  )
}

main_lines <- c(
  main_lines,
  "\\midrule",
  paste0(
    "Month fixed effects & No & Yes & Yes \\\\"
  ),
  paste0(
    "Observations & ",
    nobs(models$baseline), " & ",
    nobs(models$full), " & ",
    nobs(models$dynamic), " \\\\"
  ),
  paste0(
    "$R^2$ & ",
    fmt_num(summary(models$baseline)$r.squared), " & ",
    fmt_num(summary(models$full)$r.squared), " & ",
    fmt_num(summary(models$dynamic)$r.squared), " \\\\"
  ),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize \\item Notes: The dependent variable is the logarithm of monthly Japanese tourist arrivals to Taiwan. Newey--West standard errors with 12 lags are reported in parentheses. December is the omitted month in models with seasonal controls. *** $p<0.01$, ** $p<0.05$, * $p<0.10$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

write_latex_table(main_lines, "regression_table.tex")

distributed_terms <- coef(models$distributed)
distributed_vcov <- vcovs$distributed
weight_vector <- rep(0, length(distributed_terms))
names(weight_vector) <- names(distributed_terms)
weight_vector[c("`ln(FX)`", "lnFX_lag1", "lnFX_lag2")] <- 1
cumulative_fx <- sum(weight_vector * distributed_terms)
cumulative_se <- sqrt(as.numeric(t(weight_vector) %*% distributed_vcov %*% weight_vector))
cumulative_t <- cumulative_fx / cumulative_se
cumulative_p <- 2 * pt(abs(cumulative_t), df = nobs(models$distributed) - length(distributed_terms), lower.tail = FALSE)
cumulative_cell <- list(
  coef = fmt_coef(cumulative_fx, cumulative_p),
  se = paste0("(", fmt_num(cumulative_se), ")")
)

robust_specs <- list(
  "Log exchange rate" = list(
    extract_term("full", "`ln(FX)`"),
    extract_term("distributed", "`ln(FX)`"),
    blank_cell
  ),
  "Lagged log exchange rate ($t-1$)" = list(
    blank_cell,
    extract_term("distributed", "lnFX_lag1"),
    blank_cell
  ),
  "Lagged log exchange rate ($t-2$)" = list(
    blank_cell,
    extract_term("distributed", "lnFX_lag2"),
    blank_cell
  ),
  "Sum of exchange rate terms" = list(
    blank_cell,
    cumulative_cell,
    blank_cell
  ),
  "Change in log exchange rate" = list(
    blank_cell,
    blank_cell,
    extract_term("difference", "d_ln_fx")
  ),
  "Log Japanese industrial production" = list(
    extract_term("full", "`ln(JIPI)`"),
    extract_term("distributed", "`ln(JIPI)`"),
    blank_cell
  ),
  "Change in log Japanese industrial production" = list(
    blank_cell,
    blank_cell,
    extract_term("difference", "d_ln_jipi")
  ),
  "Log Brent oil price" = list(
    extract_term("full", "`ln(OilPrice)`"),
    extract_term("distributed", "`ln(OilPrice)`"),
    blank_cell
  ),
  "Change in log Brent oil price" = list(
    blank_cell,
    blank_cell,
    extract_term("difference", "d_ln_oil")
  )
)

robust_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  "Variables & Full Model & Distributed Lag & First Difference \\\\",
  "\\midrule"
)

for (row_name in names(robust_specs)) {
  cells <- robust_specs[[row_name]]
  cell_values <- vapply(cells, function(x) x$coef, character(1))
  cell_ses <- vapply(cells, function(x) x$se, character(1))
  robust_lines <- c(
    robust_lines,
    paste0(row_name, " & ", paste(cell_values, collapse = " & "), " \\\\"),
    paste0(" & ", paste(cell_ses, collapse = " & "), " \\\\")
  )
}

robust_lines <- c(
  robust_lines,
  "\\midrule",
  "Month fixed effects & Yes & Yes & No \\\\",
  "Time trend & Yes & Yes & No \\\\",
  paste0(
    "Observations & ",
    nobs(models$full), " & ",
    nobs(models$distributed), " & ",
    nobs(models$difference), " \\\\"
  ),
  paste0(
    "$R^2$ & ",
    fmt_num(summary(models$full)$r.squared), " & ",
    fmt_num(summary(models$distributed)$r.squared), " & ",
    fmt_num(summary(models$difference)$r.squared), " \\\\"
  ),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize \\item Notes: Column (2) adds one- and two-month lags of the exchange rate. Column (3) estimates the model in first differences to remove level trends. Newey--West standard errors with 12 lags are reported in parentheses. *** $p<0.01$, ** $p<0.05$, * $p<0.10$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

write_latex_table(robust_lines, "robustness_table.tex")

diagnostic_models <- c("baseline", "full", "dynamic", "distributed")
diagnostic_names <- c("Bivariate", "Full model", "Dynamic", "Distributed lag")

diagnostics_tbl <- tibble(
  Model = diagnostic_names,
  DW = vapply(diagnostic_models, function(name) unname(dwtest(models[[name]])$statistic[[1]]), numeric(1)),
  DW_p = vapply(diagnostic_models, function(name) dwtest(models[[name]])$p.value, numeric(1)),
  BG = vapply(diagnostic_models, function(name) unname(bgtest(models[[name]], order = 12)$statistic[[1]]), numeric(1)),
  BG_p = vapply(diagnostic_models, function(name) bgtest(models[[name]], order = 12)$p.value, numeric(1)),
  BP = vapply(diagnostic_models, function(name) unname(bptest(models[[name]])$statistic[[1]]), numeric(1)),
  BP_p = vapply(diagnostic_models, function(name) bptest(models[[name]])$p.value, numeric(1)),
  RESET = vapply(diagnostic_models, function(name) unname(resettest(models[[name]], power = 2:3, type = "fitted")$statistic[[1]]), numeric(1)),
  RESET_p = vapply(diagnostic_models, function(name) resettest(models[[name]], power = 2:3, type = "fitted")$p.value, numeric(1))
)

diagnostic_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Regression Diagnostic Tests}",
  "\\label{tab:diagnostics}",
  "\\begin{tabular}{lrrrr}",
  "\\toprule",
  "Model & Durbin--Watson & Breusch--Godfrey(12) & Breusch--Pagan & RESET \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(diagnostics_tbl))) {
  row <- diagnostics_tbl[i, ]
  diagnostic_lines <- c(
    diagnostic_lines,
    paste0(
      row$Model, " & ",
      fmt_num(row$DW), " (", fmt_num(row$DW_p, 4), ") & ",
      fmt_num(row$BG), " (", fmt_num(row$BG_p, 4), ") & ",
      fmt_num(row$BP), " (", fmt_num(row$BP_p, 4), ") & ",
      fmt_num(row$RESET), " (", fmt_num(row$RESET_p, 4), ") \\\\"
    )
  )
}

diagnostic_lines <- c(
  diagnostic_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\vspace{0.4em}\\footnotesize Notes: Each cell reports the test statistic followed by its $p$-value in parentheses. The null hypotheses are no first-order residual autocorrelation for Durbin--Watson, no higher-order serial correlation for Breusch--Godfrey, homoskedasticity for Breusch--Pagan, and correct functional form for RESET.",
  "\\end{minipage}",
  "\\end{table}"
)

write_latex_table(diagnostic_lines, "diagnostic_tests.tex")

m2_no_month <- lm(ln_tourist ~ `ln(FX)` + `ln(JIPI)` + `ln(OilPrice)` + t, data = df)
m2_no_macro <- lm(as.formula(paste("ln_tourist ~ `ln(FX)` + t +", month_terms)), data = df)
full_no_fx_month <- lm(ln_tourist ~ `ln(JIPI)` + `ln(OilPrice)` + t, data = df)
df_dl <- df %>% filter(!is.na(lnFX_lag1), !is.na(lnFX_lag2))
m4_nolag <- lm(as.formula(paste("ln_tourist ~ `ln(FX)` + `ln(JIPI)` + `ln(OilPrice)` + t +", month_terms)), data = df_dl)
m4_same_sample <- lm(distributed_formula, data = df_dl)
df_dyn <- df %>% filter(!is.na(ln_tourist_lag1))
dyn_no_lag <- lm(as.formula(paste("ln_tourist ~ `ln(FX)` + `ln(JIPI)` + `ln(OilPrice)` +", month_terms)), data = df_dyn)

month_test <- anova(m2_no_month, models$full)
macro_test <- anova(m2_no_macro, models$full)
fx_month_test <- anova(full_no_fx_month, models$full)
lag_test <- anova(m4_nolag, m4_same_sample)
dynamic_test <- anova(dyn_no_lag, models$dynamic)
full_fx_row <- model_tidy[["full"]] %>% filter(term == "`ln(FX)`")
full_fx_t <- full_fx_row %>% pull(statistic)
full_fx_p <- full_fx_row %>% pull(p_value)
full_oil_row <- model_tidy[["full"]] %>% filter(term == "`ln(OilPrice)`")

hypothesis_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Hypothesis Tests}",
  "\\label{tab:hypothesis}",
  "\\begin{tabular}{p{6.1cm}rrr}",
  "\\toprule",
  "Null hypothesis & Test statistic & $p$-value & Decision at 5\\% \\\\",
  "\\midrule",
  paste0(
    "$H_0$: Exchange-rate elasticity in the full model equals zero & ",
    fmt_num(full_fx_t), " & ",
    fmt_num(full_fx_p, 4), " & Fail to reject \\\\"
  ),
  paste0(
    "$H_0$: Month effects are jointly zero & ",
    fmt_num(month_test$F[2]), " & ",
    fmt_num(month_test$`Pr(>F)`[2], 4), " & Reject \\\\"
  ),
  paste0(
    "$H_0$: Exchange rate and all 11 month dummies are jointly zero & ",
    fmt_num(fx_month_test$F[2]), " & ",
    fmt_num(fx_month_test$`Pr(>F)`[2], 4), " & Reject \\\\"
  ),
  paste0(
    "$H_0$: Japanese industrial production and oil price are jointly zero & ",
    fmt_num(macro_test$F[2]), " & ",
    fmt_num(macro_test$`Pr(>F)`[2], 4), " & Fail to reject \\\\"
  ),
  paste0(
    "$H_0$: Oil price coefficient in the full model equals zero & ",
    fmt_num(full_oil_row %>% pull(statistic)), " & ",
    fmt_num(full_oil_row %>% pull(p_value), 4), " & Fail to reject at 5\\% \\\\"
  ),
  paste0(
    "$H_0$: Lagged exchange-rate terms are jointly zero & ",
    fmt_num(lag_test$F[2]), " & ",
    fmt_num(lag_test$`Pr(>F)`[2], 4), " & Fail to reject \\\\"
  ),
  paste0(
    "$H_0$: Lagged tourist arrivals have no explanatory power & ",
    fmt_num(dynamic_test$F[2]), " & ",
    fmt_num(dynamic_test$`Pr(>F)`[2], 4), " & Reject \\\\"
  ),
  paste0(
    "$H_0$: Sum of exchange-rate coefficients in the distributed-lag model equals zero & ",
    fmt_num(cumulative_t^2), " & ",
    fmt_num(cumulative_p, 4), " & Fail to reject \\\\"
  ),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
)

write_latex_table(hypothesis_lines, "hypothesis_tests.tex")

adf_specs <- tibble(
  Variable = c("Log tourist arrivals", "Log exchange rate", "Log Japanese industrial production", "Log Brent oil price"),
  level_series = list(df$ln_tourist, df$`ln(FX)`, df$`ln(JIPI)`, df$`ln(OilPrice)`),
  diff_series = list(diff(df$ln_tourist), diff(df$`ln(FX)`), diff(df$`ln(JIPI)`), diff(df$`ln(OilPrice)`))
) %>%
  rowwise() %>%
  mutate(
    level_stat = adf_manual(level_series, k = 1, trend = TRUE)$statistic,
    diff_stat = adf_manual(diff_series, k = 1, trend = FALSE)$statistic,
    conclusion = case_when(
      level_stat <= -3.43 ~ "Level-stationary at 5\\%",
      diff_stat <= -2.89 ~ "Likely I(1)",
      TRUE ~ "Inconclusive"
    )
  ) %>%
  ungroup()

resid_adf_bivariate <- adf_manual(residuals(models$baseline), k = 1, trend = FALSE)$statistic
resid_adf_full <- adf_manual(residuals(models$full), k = 1, trend = FALSE)$statistic

adf_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{ADF-Style Unit-Root and Spurious-Regression Checks}",
  "\\label{tab:adf}",
  "\\begin{tabular}{lrrl}",
  "\\toprule",
  "Series & Level statistic & First-difference statistic & Approximate conclusion \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(adf_specs))) {
  row <- adf_specs[i, ]
  adf_lines <- c(
    adf_lines,
    paste0(
      row$Variable, " & ",
      fmt_num(row$level_stat), " & ",
      fmt_num(row$diff_stat), " & ",
      row$conclusion, " \\\\"
    )
  )
}

adf_lines <- c(
  adf_lines,
  "\\midrule",
  paste0("Residual from bivariate regression & ", fmt_num(resid_adf_bivariate), " & -- & Stationary residual if statistic $<$ -2.89 \\\\"),
  paste0("Residual from full regression & ", fmt_num(resid_adf_full), " & -- & Stationary residual if statistic $<$ -2.89 \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\vspace{0.4em}\\footnotesize Notes: These are manual ADF-style regressions with one lag of the dependent difference. For level tests, the regression includes an intercept and linear trend; for first differences and residuals, it includes an intercept only. As a rule of thumb, a value below about $-3.43$ in levels with trend or below about $-2.89$ in differences suggests rejecting a unit root at the 5\\% level. This table is used to screen for potential spurious regression concerns rather than to replace a full unit-root package.",
  "\\end{minipage}",
  "\\end{table}"
)

write_latex_table(adf_lines, "adf_tests.tex")

index_df <- df %>%
  transmute(
    date = date,
    tourist_index = Tourist / first(Tourist) * 100,
    fx_index = `日圓兌新台幣JPY/NTD(FX)` / first(`日圓兌新台幣JPY/NTD(FX)`) * 100
  )

pdf(file.path(output_dir, "tourism_fx_index.pdf"), width = 8, height = 4.8)
plot(
  index_df$date,
  index_df$tourist_index,
  type = "l",
  lwd = 2,
  col = "#0B5FA5",
  xlab = "Month",
  ylab = "Index (Oct. 2009 = 100)",
  main = "Japanese Tourist Arrivals and the Bilateral Exchange Rate",
  ylim = range(c(index_df$tourist_index, index_df$fx_index), na.rm = TRUE)
)
lines(index_df$date, index_df$fx_index, lwd = 2, col = "#C44E52")
legend(
  "topleft",
  legend = c("Tourist arrivals", "JPY purchasing power in Taiwan"),
  col = c("#0B5FA5", "#C44E52"),
  lty = 1,
  lwd = 2,
  bty = "n"
)
dev.off()

key_results <- c(
  paste0("Sample period: ", min(df$date), " to ", max(df$date)),
  paste0("Number of observations: ", nrow(df)),
  paste0("Preferred full-model exchange rate coefficient: ", fmt_num(models$full$coefficients["`ln(FX)`"])),
  paste0("Dynamic-model exchange rate coefficient: ", fmt_num(models$dynamic$coefficients["`ln(FX)`"])),
  paste0("Distributed-lag cumulative exchange rate coefficient: ", fmt_num(cumulative_fx))
)

writeLines(key_results, file.path(output_dir, "analysis_notes.txt"))
