options(repos = c(CRAN = "https://cloud.r-project.org"))

required_packages <- c("readxl", "tseries", "lmtest", "sandwich")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  install.packages(missing_packages, quiet = TRUE)
}

suppressPackageStartupMessages({
  library(readxl)
  library(tseries)
  library(lmtest)
  library(sandwich)
})

dir.create("tables", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

Data_t_1 <- read_excel("Data-t=1.xlsx")

# Add a calendar index consistent with the AGENTS guidance:
# the uploaded estimation sample contains 120 monthly observations from 2010-01 to 2019-12.
Data_t_1$Date <- seq(as.Date("2010-01-01"), by = "month", length.out = nrow(Data_t_1))
Data_t_1$MonthName <- factor(format(Data_t_1$Date, "%b"),
                             levels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"))

manual_vif <- function(model) {
  X <- model.matrix(model)
  X <- X[, colnames(X) != "(Intercept)", drop = FALSE]
  out <- numeric(ncol(X))
  names(out) <- colnames(X)
  for (i in seq_len(ncol(X))) {
    y <- X[, i]
    others <- X[, -i, drop = FALSE]
    fit <- lm(y ~ others)
    out[i] <- 1 / (1 - summary(fit)$r.squared)
  }
  out
}

fmt_num <- function(x, digits = 3) formatC(x, format = "f", digits = digits)
fmt_p <- function(x, digits = 3) {
  if (is.na(x)) return("")
  if (x < 0.001) return("$<0.001$")
  formatC(x, format = "f", digits = digits)
}

star_code <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  ""
}

write_lines <- function(path, lines) {
  writeLines(lines, con = path, useBytes = TRUE)
}

escape_tex <- function(x) {
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([#$%&_{}])", "\\\\\\1", x, perl = TRUE)
  x
}

# -------------------------------------------------------------------------
# Unit-root tests
# -------------------------------------------------------------------------

adf_levels <- list(
  list(name = "$\\ln(\\mathrm{Tourist}_t)$", vec = Data_t_1$`ln(Tourist)`),
  list(name = "$\\ln(\\mathrm{FX}_t)$", vec = Data_t_1$`ln(FX)`),
  list(name = "$\\ln(\\mathrm{JIPI}_t)$", vec = Data_t_1$`ln(JIPI)`),
  list(name = "$\\ln(\\mathrm{OilPrice}_t)$", vec = Data_t_1$`ln(OilPrice)`)
)

adf_transformed <- list(
  list(name = "$\\ln(\\mathrm{Tourist}_t)$", vec = Data_t_1$`ln(Tourist)`),
  list(name = "$\\Delta \\ln(\\mathrm{FX}_t)$", vec = Data_t_1$`d_ln(FX)`),
  list(name = "$\\ln(\\mathrm{JIPI}_t)$", vec = Data_t_1$`ln(JIPI)`),
  list(name = "$\\Delta \\ln(\\mathrm{OilPrice}_t)$", vec = Data_t_1$`d_ln(OilPrice)`)
)

run_adf_block <- function(specs) {
  lapply(specs, function(spec) {
    test <- adf.test(spec$vec)
    conclusion <- if (test$p.value < 0.05) "Stationary" else "Non-stationary"
    list(
      name = spec$name,
      stat = unname(test$statistic),
      lag = unname(test$parameter),
      p = test$p.value,
      conclusion = conclusion
    )
  })
}

adf_level_results <- run_adf_block(adf_levels)
adf_diff_results <- run_adf_block(adf_transformed)

write_adf_table <- function(path, caption, label, rows) {
  lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    paste0("\\caption{", caption, "}"),
    paste0("\\label{", label, "}"),
    "\\begin{tabular}{lrrrl}",
    "\\toprule",
    "Variable & ADF statistic & Lag order & p-value & Conclusion \\\\",
    "\\midrule"
  )
  for (row in rows) {
    lines <- c(
      lines,
      paste0(row$name, " & ",
             fmt_num(row$stat, 4), " & ",
             row$lag, " & ",
             fmt_p(row$p), " & ",
             row$conclusion, " \\\\")
    )
  }
  lines <- c(lines, "\\bottomrule", "\\end{tabular}", "\\end{table}")
  write_lines(path, lines)
}

write_adf_table(
  "tables/adf_levels.tex",
  "ADF tests for variables in levels (R output)",
  "tab:adf-levels",
  adf_level_results
)
write_adf_table(
  "tables/adf_transformed.tex",
  "ADF tests after the required transformations (R output)",
  "tab:adf-transformed",
  adf_diff_results
)

# -------------------------------------------------------------------------
# Models
# -------------------------------------------------------------------------

model01 <- lm(
  `ln(Tourist)` ~ `d_ln(FX)` + `ln(JIPI)` + `d_ln(OilPrice)` + t +
    Month1 + Month2 + Month3 + Month4 + Month5 + Month6 +
    Month7 + Month8 + Month9 + Month10 + Month11,
  data = Data_t_1
)

model02 <- lm(
  `ln(Tourist)` ~ `ln(Tourist-1)` + `d_ln(FX)` + `d_ln(FX-1)` + `d_ln(FX-2)` +
    `ln(JIPI)` + `ln(JIPI-1)` + `ln(JIPI-2)` +
    `d_ln(OilPrice)` + `d_ln(OilPrice-1)` + `d_ln(OilPrice-2)` + t +
    Month1 + Month2 + Month3 + Month4 + Month5 + Month6 +
    Month7 + Month8 + Month9 + Month10 + Month11,
  data = Data_t_1
)

hac01 <- coeftest(model01, vcov. = vcovHAC(model01))
hac02 <- coeftest(model02, vcov. = vcovHAC(model02))
bg01 <- bgtest(model01, order = 1)
bg02 <- bgtest(model02, order = 1)
vif01 <- manual_vif(model01)
vif02 <- manual_vif(model02)
sum01 <- summary(model01)
sum02 <- summary(model02)

f_pvalue <- function(model_summary) {
  fstat <- model_summary$fstatistic
  unname(pf(fstat[1], fstat[2], fstat[3], lower.tail = FALSE))
}

row_value <- function(ct, name, column) ct[name, column, drop = TRUE]

coef_table <- data.frame(
  label = c(
    "$\\Delta \\ln(\\mathrm{FX}_t)$",
    "$\\Delta \\ln(\\mathrm{FX}_{t-1})$",
    "$\\Delta \\ln(\\mathrm{FX}_{t-2})$",
    "$\\ln(\\mathrm{Tourist}_{t-1})$",
    "$\\ln(\\mathrm{JIPI}_t)$",
    "$\\ln(\\mathrm{JIPI}_{t-1})$",
    "$\\ln(\\mathrm{JIPI}_{t-2})$",
    "$\\Delta \\ln(\\mathrm{OilPrice}_t)$",
    "$\\Delta \\ln(\\mathrm{OilPrice}_{t-1})$",
    "$\\Delta \\ln(\\mathrm{OilPrice}_{t-2})$",
    "Time trend"
  ),
  m1_name = c("`d_ln(FX)`", NA, NA, NA, "`ln(JIPI)`", NA, NA, "`d_ln(OilPrice)`", NA, NA, "t"),
  m2_name = c("`d_ln(FX)`", "`d_ln(FX-1)`", "`d_ln(FX-2)`", "`ln(Tourist-1)`", "`ln(JIPI)`", "`ln(JIPI-1)`", "`ln(JIPI-2)`",
              "`d_ln(OilPrice)`", "`d_ln(OilPrice-1)`", "`d_ln(OilPrice-2)`", "t"),
  stringsAsFactors = FALSE
)

coef_line <- function(ct, name) {
  if (is.na(name)) return(list(coef = "---", se = ""))
  beta <- row_value(ct, name, 1)
  se <- row_value(ct, name, 2)
  p <- row_value(ct, name, 4)
  list(coef = paste0(fmt_num(beta, 3), star_code(p)), se = paste0("(", fmt_num(se, 3), ")"))
}

write_regression_table <- function() {
  lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Stata-style regression table based on R estimates}",
    "\\label{tab:main-results}",
    "\\small",
    "\\begin{tabular}{lcc}",
    "\\toprule",
    "Variable & (1) Static model & (2) Dynamic lag model \\\\",
    "\\midrule"
  )

  for (i in seq_len(nrow(coef_table))) {
    line1 <- coef_line(hac01, coef_table$m1_name[i])
    line2 <- coef_line(hac02, coef_table$m2_name[i])
    lines <- c(
      lines,
      paste0(coef_table$label[i], " & ", line1$coef, " & ", line2$coef, " \\\\"),
      paste0(" & ", line1$se, " & ", line2$se, " \\\\")
    )
  }

  lines <- c(
    lines,
    paste0("Observations & ", nobs(model01), " & ", nobs(model02), " \\\\"),
    paste0("Adjusted $R^2$ & ", fmt_num(sum01$adj.r.squared, 4), " & ", fmt_num(sum02$adj.r.squared, 4), " \\\\"),
    "HAC standard errors & Yes & Yes \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "\\vspace{0.4em}",
    "\\begin{minipage}{0.92\\textwidth}",
    "\\footnotesize",
    "Notes: Newey-West HAC robust standard errors are reported in parentheses. Significance levels are based on HAC p-values. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
    "\\end{minipage}",
    "\\end{table}"
  )
  write_lines("tables/results_table.tex", lines)
}

write_regression_table()

month_rows <- data.frame(
  label = c("January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November"),
  m1_name = paste0("Month", 1:11),
  m2_name = paste0("Month", 1:11),
  stringsAsFactors = FALSE
)

write_month_table <- function() {
  lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Monthly dummy coefficients with HAC inference (December as the base month)}",
    "\\label{tab:month-effects}",
    "\\small",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    "Month & Model 1 coef. & Model 1 $p$ & Model 2 coef. & Model 2 $p$ \\\\",
    "\\midrule"
  )
  for (i in seq_len(nrow(month_rows))) {
    beta1 <- row_value(hac01, month_rows$m1_name[i], 1)
    p1 <- row_value(hac01, month_rows$m1_name[i], 4)
    beta2 <- row_value(hac02, month_rows$m2_name[i], 1)
    p2 <- row_value(hac02, month_rows$m2_name[i], 4)
    lines <- c(
      lines,
      paste0(month_rows$label[i], " & ",
             fmt_num(beta1, 3), star_code(p1), " & ",
             fmt_p(p1), " & ",
             fmt_num(beta2, 3), star_code(p2), " & ",
             fmt_p(p2), " \\\\")
    )
  }
  lines <- c(
    lines,
    "\\bottomrule",
    "\\end{tabular}",
    "\\vspace{0.4em}",
    "\\begin{minipage}{0.94\\textwidth}",
    "\\footnotesize",
    "Notes: Coefficients are measured relative to December. HAC/Newey-West p-values are reported. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
    "\\end{minipage}",
    "\\end{table}"
  )
  write_lines("tables/month_effects_table.tex", lines)
}

write_month_table()

# -------------------------------------------------------------------------
# Diagnostics / robustness tables
# -------------------------------------------------------------------------

desc <- data.frame(
  Variable = c("$\\ln(\\mathrm{Tourist}_t)$", "$\\Delta \\ln(\\mathrm{FX}_t)$", "$\\ln(\\mathrm{JIPI}_t)$", "$\\Delta \\ln(\\mathrm{OilPrice}_t)$"),
  Mean = c(mean(Data_t_1$`ln(Tourist)`), mean(Data_t_1$`d_ln(FX)`), mean(Data_t_1$`ln(JIPI)`), mean(Data_t_1$`d_ln(OilPrice)`)),
  SD = c(sd(Data_t_1$`ln(Tourist)`), sd(Data_t_1$`d_ln(FX)`), sd(Data_t_1$`ln(JIPI)`), sd(Data_t_1$`d_ln(OilPrice)`)),
  Min = c(min(Data_t_1$`ln(Tourist)`), min(Data_t_1$`d_ln(FX)`), min(Data_t_1$`ln(JIPI)`), min(Data_t_1$`d_ln(OilPrice)`)),
  Max = c(max(Data_t_1$`ln(Tourist)`), max(Data_t_1$`d_ln(FX)`), max(Data_t_1$`ln(JIPI)`), max(Data_t_1$`d_ln(OilPrice)`))
)

lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Descriptive statistics for the transformed variables used in estimation}",
  "\\label{tab:summary-stats}",
  "\\begin{tabular}{lrrrr}",
  "\\toprule",
  "Variable & Mean & Std. Dev. & Min & Max \\\\",
  "\\midrule"
)
for (i in seq_len(nrow(desc))) {
  lines <- c(lines, paste0(desc$Variable[i], " & ", fmt_num(desc$Mean[i], 4), " & ", fmt_num(desc$SD[i], 4), " & ", fmt_num(desc$Min[i], 4), " & ", fmt_num(desc$Max[i], 4), " \\\\"))
}
lines <- c(lines, "\\bottomrule", "\\end{tabular}", "\\end{table}")
write_lines("tables/summary_stats.tex", lines)

diag_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Diagnostic and robustness checks based on R output}",
  "\\label{tab:diagnostics}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Diagnostic item & Model 1 & Model 2 \\\\",
  "\\midrule",
  paste0("Overall F-statistic & ", fmt_num(unname(sum01$fstatistic[1]), 2), " & ", fmt_num(unname(sum02$fstatistic[1]), 2), " \\\\"),
  paste0("F-test p-value & ", fmt_p(f_pvalue(sum01)), " & ", fmt_p(f_pvalue(sum02)), " \\\\"),
  paste0("Breusch-Godfrey LM statistic & ", fmt_num(unname(bg01$statistic), 3), " & ", fmt_num(unname(bg02$statistic), 3), " \\\\"),
  paste0("Breusch-Godfrey p-value & ", fmt_p(bg01$p.value), " & ", fmt_p(bg02$p.value), " \\\\"),
  paste0("Maximum VIF & ", fmt_num(max(vif01), 2), " & ", fmt_num(max(vif02), 2), " \\\\"),
  paste0("Adjusted $R^2$ & ", fmt_num(sum01$adj.r.squared, 4), " & ", fmt_num(sum02$adj.r.squared, 4), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
)
write_lines("tables/diagnostics_table.tex", diag_lines)

macro_lines <- c(
  paste0("\\newcommand{\\StaticAdjRtwo}{", fmt_num(sum01$adj.r.squared, 4), "}"),
  paste0("\\newcommand{\\DynamicAdjRtwo}{", fmt_num(sum02$adj.r.squared, 4), "}"),
  paste0("\\newcommand{\\StaticFstat}{", fmt_num(unname(sum01$fstatistic[1]), 2), "}"),
  paste0("\\newcommand{\\DynamicFstat}{", fmt_num(unname(sum02$fstatistic[1]), 2), "}"),
  paste0("\\newcommand{\\StaticFp}{", fmt_p(f_pvalue(sum01)), "}"),
  paste0("\\newcommand{\\DynamicFp}{", fmt_p(f_pvalue(sum02)), "}"),
  paste0("\\newcommand{\\StaticFX}{", fmt_num(row_value(hac01, "`d_ln(FX)`", 1), 3), "}"),
  paste0("\\newcommand{\\StaticFXP}{", fmt_p(row_value(hac01, "`d_ln(FX)`", 4)), "}"),
  paste0("\\newcommand{\\DynamicFX}{", fmt_num(row_value(hac02, "`d_ln(FX)`", 1), 3), "}"),
  paste0("\\newcommand{\\DynamicFXP}{", fmt_p(row_value(hac02, "`d_ln(FX)`", 4)), "}"),
  paste0("\\newcommand{\\LagTourist}{", fmt_num(row_value(hac02, "`ln(Tourist-1)`", 1), 3), "}"),
  paste0("\\newcommand{\\LagTouristP}{", fmt_p(row_value(hac02, "`ln(Tourist-1)`", 4)), "}"),
  paste0("\\newcommand{\\StaticOil}{", fmt_num(row_value(hac01, "`d_ln(OilPrice)`", 1), 3), "}"),
  paste0("\\newcommand{\\StaticOilP}{", fmt_p(row_value(hac01, "`d_ln(OilPrice)`", 4)), "}"),
  paste0("\\newcommand{\\DynamicJIPI}{", fmt_num(row_value(hac02, "`ln(JIPI)`", 1), 3), "}"),
  paste0("\\newcommand{\\DynamicJIPIP}{", fmt_p(row_value(hac02, "`ln(JIPI)`", 4)), "}"),
  paste0("\\newcommand{\\BGStaticP}{", fmt_p(bg01$p.value), "}"),
  paste0("\\newcommand{\\BGDynamicP}{", fmt_p(bg02$p.value), "}"),
  paste0("\\newcommand{\\MaxVIFStatic}{", fmt_num(max(vif01), 2), "}"),
  paste0("\\newcommand{\\MaxVIFDynamic}{", fmt_num(max(vif02), 2), "}")
)
write_lines("tables/report_macros.tex", macro_lines)

# -------------------------------------------------------------------------
# Figures based strictly on the uploaded data and model outputs
# -------------------------------------------------------------------------

index_base100 <- function(x) {
  100 * x / x[1]
}

pdf("figures/figure1_tourist_trend.pdf", width = 8.5, height = 4.8)
par(mar = c(4, 4, 2, 1))
plot(Data_t_1$Date, Data_t_1$Tourist, type = "l", lwd = 2, col = "#1B3C73",
     xlab = "", ylab = "Japanese tourist arrivals",
     main = "Japanese Tourist Arrivals to Taiwan, 2010--2019")
grid(col = "gray85")
dev.off()

pdf("figures/figure2_seasonality.pdf", width = 8.2, height = 4.8)
season_means <- aggregate(Tourist ~ MonthName, data = Data_t_1, FUN = mean)
barplot(season_means$Tourist,
        names.arg = season_means$MonthName,
        col = "#6A9AB0",
        border = NA,
        ylab = "Average arrivals",
        main = "Average Japanese Tourist Arrivals by Calendar Month")
grid(nx = NA, ny = NULL, col = "gray85")
dev.off()

tourist_idx <- index_base100(Data_t_1$Tourist)
fx_idx <- index_base100(Data_t_1$FX)
oil_idx <- index_base100(Data_t_1$OilPrice)
jipi_idx <- index_base100(Data_t_1$JIPI)

pdf("figures/figure3_tourist_fx_index.pdf", width = 8.5, height = 4.8)
par(mar = c(4, 4, 2, 1))
plot(Data_t_1$Date, tourist_idx, type = "l", lwd = 2.2, col = "#1B3C73",
     xlab = "", ylab = "Index (2010-01 = 100)",
     main = "Indexed Tourist Arrivals and Exchange Rate")
lines(Data_t_1$Date, fx_idx, lwd = 2, col = "#C84C09")
grid(col = "gray85")
legend("topleft",
       legend = c("Tourist arrivals", "JPY/TWD exchange-rate index"),
       col = c("#1B3C73", "#C84C09"), lwd = c(2.2, 2), bty = "n")
dev.off()

pdf("figures/figure4_tourist_oil_index.pdf", width = 8.5, height = 4.8)
par(mar = c(4, 4, 2, 1))
plot(Data_t_1$Date, tourist_idx, type = "l", lwd = 2.2, col = "#1B3C73",
     xlab = "", ylab = "Index (2010-01 = 100)",
     main = "Indexed Tourist Arrivals and Oil Price")
lines(Data_t_1$Date, oil_idx, lwd = 2, col = "#2A7F62")
grid(col = "gray85")
legend("topleft",
       legend = c("Tourist arrivals", "Brent oil price"),
       col = c("#1B3C73", "#2A7F62"), lwd = c(2.2, 2), bty = "n")
dev.off()

pdf("figures/figure5_tourist_jipi_index.pdf", width = 8.5, height = 4.8)
par(mar = c(4, 4, 2, 1))
plot(Data_t_1$Date, tourist_idx, type = "l", lwd = 2.2, col = "#1B3C73",
     xlab = "", ylab = "Index (2010-01 = 100)",
     main = "Indexed Tourist Arrivals and Japan Industrial Production")
lines(Data_t_1$Date, jipi_idx, lwd = 2, col = "#7A3E9D")
grid(col = "gray85")
legend("topleft",
       legend = c("Tourist arrivals", "Japan industrial production index"),
       col = c("#1B3C73", "#7A3E9D"), lwd = c(2.2, 2), bty = "n")
dev.off()

pdf("figures/figure6_actual_vs_fitted.pdf", width = 8.5, height = 5.2)
par(mfrow = c(2, 1), mar = c(3.5, 4, 2, 1))
plot(Data_t_1$Date, Data_t_1$`ln(Tourist)`, type = "l", lwd = 2, col = "black",
     xlab = "", ylab = "log arrivals",
     main = "Actual vs fitted values: Model 01")
lines(Data_t_1$Date, fitted(model01), col = "#D55E00", lwd = 2)
grid(col = "gray85")
legend("topleft", legend = c("Actual", "Fitted"), col = c("black", "#D55E00"), lwd = 2, bty = "n")

plot(Data_t_1$Date, Data_t_1$`ln(Tourist)`, type = "l", lwd = 2, col = "black",
     xlab = "", ylab = "log arrivals",
     main = "Actual vs fitted values: Model 02")
lines(Data_t_1$Date, fitted(model02), col = "#0072B2", lwd = 2)
grid(col = "gray85")
legend("topleft", legend = c("Actual", "Fitted"), col = c("black", "#0072B2"), lwd = 2, bty = "n")
dev.off()
