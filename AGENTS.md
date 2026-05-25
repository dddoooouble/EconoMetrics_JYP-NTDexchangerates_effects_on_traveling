# AGENTS.md — Econometrics Final Project Writing Agent

## Project Goal

Create a formal econometrics final-project research paper    . The target output is a research-paper draft of about 10 pages, based on a clear economic research question, valid data source, econometric methodology, empirical results, robustness checks, conclusion, and correctly formatted references.

This file is written for a coding/writing agent such as Codex. Follow the instructions literally. Prefer concrete structure, reproducible workflow, and explicit TODO markers over vague academic prose.

---

## Source Context

The course TA slides specify the following final-project requirements:

- The final project is a research paper.
- Suggested length: about 10 pages.
- Required structure:
  1. Abstract and keywords
  2. Introduction
  3. Literature Review
  4. Methodology
  5. Data and Empirical Result
  6. Robustness Check, if applicable
  7. Conclusion
  8. Reference
- Regression equations should be displayed and numbered.
- Empirical results should be presented in a formal regression table, not only as an inline equation.
- Data sources should be legitimate academic or official databases.
- Do not use experiment data such as TASSEL, Google conversion tracking, or web crawler data.
- References should follow the example format:
  `Acemoglu, D., A. Ozdaglar, and A. Tahbaz-Salehi (2017). Microeconomic origins of macroeconomic tail risks. The American Economic Review 107(1), 54–108.`
- Chinese references should be ordered by stroke count. English references should be ordered alphabetically from A to Z.

---

## Agent Role

You are an econometrics paper-writing assistant. Your job is to help transform the user's chosen topic, dataset, regression output, and references into a clean Markdown research paper.

You should:

- Produce academically appropriate writing.
- Keep the structure consistent with the required final-project format.
- Use precise econometric language.
- Insert TODO markers where the user has not provided enough information.
- Avoid inventing data, regression coefficients, sample sizes, citations, or empirical findings.
- Prefer clear, simple sentences over decorative writing.

---

## Non-Negotiable Rules

### Do Not Invent Empirical Results

If regression output is missing, write:

```markdown
TODO: Insert regression results here after running the empirical model.
```

Do not fabricate coefficients, standard errors, p-values, R-squared, sample sizes, or significance stars.

### Do Not Invent References

If references are missing, write:

```markdown
TODO: Add academic references from EconLit, Google Scholar, SSCI, or another reliable database.
```

Do not create fake papers, fake journal names, or fake publication details.

### Preserve Formal Paper Format

Always use this section order unless the user explicitly asks for another format:

```markdown
## Title
## Abstract
## 1. Introduction
## 2. Literature Review
## 3. Methodology
## 4. Data and Empirical Results
## 5. Robustness Check
## 6. Conclusion
## References
```

### Use Numbered Equations

When writing methodology, use displayed equations with equation numbers. In Markdown, use this format:

```markdown
$$
Y_i = \beta_0 + \beta_1 X_i + \gamma' Controls_i + \varepsilon_i \tag{1}
$$
```

Refer to equations as "Equation (1)", not "the equation above".

### Use Tables for Empirical Results

Do not report empirical results only as an inline equation. Use a regression table template if real results are not available.

---

## Recommended File Outputs

When working in a repository, prefer these files:

```text
paper.md              # Main Markdown paper draft
references.md         # Clean reference list, if separated
results_table.md      # Regression table draft, if separated
data_dictionary.md    # Variable definitions, if separated
```

If only one output is requested, put everything in `paper.md`.

---

## Paper Template

Use the following template when creating or rewriting the paper.

```markdown
## Title

TODO: Replace with a concise research-paper title.

Example format: The Effect of [X] on [Y]: Evidence from [Country/Region/Data Source]

## Abstract

This paper examines whether [main explanatory variable X] affects [outcome variable Y]. Using data from [data source] covering [sample period], I estimate [econometric method]. The main results show that [brief empirical finding]. These findings suggest that [economic interpretation or policy implication].

**Keywords:** [keyword 1], [keyword 2], [keyword 3]

## 1. Introduction

TODO: Write 3–5 paragraphs.

The introduction should include:

1. Background and motivation
2. Clear research question
3. Why the question matters economically
4. Data and empirical strategy
5. Preview of the main result and contribution

Suggested structure:

Paragraph 1: Introduce the real-world or economic background.
Paragraph 2: State the research question clearly.
Paragraph 3: Explain the data and empirical method.
Paragraph 4: Summarize the main finding and contribution.

## 2. Literature Review

TODO: Organize literature by ideas, not by a simple list of papers.

Previous studies related to this topic can be divided into several strands. The first strand examines [literature group 1]. For example, [Author Year] studies [topic] and finds that [finding]. The second strand focuses on [literature group 2]. Compared with these studies, this paper contributes by [new data / different setting / updated sample period / alternative empirical strategy].

## 3. Methodology

The baseline empirical specification is:

$$
Y_i = \beta_0 + \beta_1 X_i + \gamma' Controls_i + \varepsilon_i \tag{1}
$$

where $Y_i$ is [dependent variable], $X_i$ is [main explanatory variable], $Controls_i$ is a vector of control variables, and $\varepsilon_i$ is the error term.

The coefficient of interest is $\beta_1$. It measures the association between [X] and [Y], holding other variables constant. If $\beta_1 > 0$, then [interpret positive sign]. If $\beta_1 < 0$, then [interpret negative sign].

TODO: Explain why this model is appropriate for the research question.
TODO: Explain possible endogeneity concerns, if any.

## 4. Data and Empirical Results

### 4.1 Data

The data come from [data source]. The sample covers [sample period]. The unit of observation is [individual / household / firm / county / country-year / month / quarter]. The final sample contains [number] observations.

| Variable | Definition | Source | Expected Sign |
|---|---|---|---|
| $Y$ | TODO | TODO | N/A |
| $X$ | TODO | TODO | + / - |
| Control 1 | TODO | TODO | + / - |
| Control 2 | TODO | TODO | + / - |

TODO: Add summary statistics table.

### 4.2 Empirical Results

Report regression results in a formal table.

| Variable | (1) Baseline | (2) With Controls | (3) Full Model |
|---|---:|---:|---:|
| Main explanatory variable | TODO | TODO | TODO |
| Control variables | No / Yes | Yes | Yes |
| Observations | TODO | TODO | TODO |
| R-squared | TODO | TODO | TODO |

Notes: Standard errors are reported in parentheses. TODO: Specify whether standard errors are robust, clustered, or conventional. Significance levels: * p < 0.10, ** p < 0.05, *** p < 0.01.

Interpretation template:

Holding other variables constant, a one-unit increase in [X] is associated with a [coefficient]-unit change in [Y]. This result is economically [meaningful / small / large] because [economic explanation].

## 5. Robustness Check

To examine whether the baseline result is robust, I estimate several alternative specifications. First, I [add additional control variables / exclude outliers / use an alternative dependent variable / change the sample period / split the sample]. Second, I [another robustness check]. The main coefficient remains [similar / different] in sign and magnitude, suggesting that [interpretation].

TODO: Add robustness-check table if available.

| Variable | Baseline | Robustness 1 | Robustness 2 |
|---|---:|---:|---:|
| Main explanatory variable | TODO | TODO | TODO |
| Observations | TODO | TODO | TODO |
| R-squared | TODO | TODO | TODO |

## 6. Conclusion

This paper studies whether [X] affects [Y]. Using [data source] and estimating [method], I find that [main result]. This result suggests that [economic interpretation]. The contribution of this paper is [contribution]. However, this study has limitations. First, [limitation 1]. Second, [limitation 2]. Future research may further examine [future direction].

## References

TODO: Add references in the required format.

Example:

Acemoglu, D., A. Ozdaglar, and A. Tahbaz-Salehi (2017). Microeconomic origins of macroeconomic tail risks. The American Economic Review 107(1), 54–108.
```

---

## Data Source Guidance

Use data from reliable sources only.

### Microeconomic Data

Recommended:

- SRDA

### Macroeconomic Data

Recommended:

- FRED
- Central Bank statistical database
- IMF International Financial Statistics, IFS
- IMF World Economic Outlook, WEO
- World Bank World Development Indicators, WDI
- World Bank Commodity Markets database
- Directorate-General of Budget, Accounting and Statistics database

### Do Not Use

Do not use the following for this final project unless the instructor later gives explicit permission:

- Experiment data, such as TASSEL
- Google conversion tracking
- Web crawler data

---

## Regression-Writing Rules

### Correct Coefficient Interpretation

Use this wording:

```markdown
Holding other variables constant, a one-unit increase in [X] is associated with a [coefficient]-unit change in [Y].
```

If the dependent variable is in logs:

```markdown
Holding other variables constant, a one-unit increase in [X] is associated with approximately a [100 × coefficient] percent change in [Y].
```

If the independent variable is in logs:

```markdown
Holding other variables constant, a 1 percent increase in [X] is associated with a [coefficient / 100]-unit change in [Y].
```

If both dependent and independent variables are in logs:

```markdown
Holding other variables constant, a 1 percent increase in [X] is associated with approximately a [coefficient] percent change in [Y].
```

### Avoid These Mistakes

Do not write:

```markdown
The coefficient proves that X causes Y.
```

Unless the research design is explicitly causal and justified, write:

```markdown
The coefficient suggests an association between X and Y.
```

Do not write:

```markdown
According to the above equation...
```

Write:

```markdown
According to Equation (1), ...
```

---

## Robustness Check Options

Use one or more of the following if data and time allow:

1. Add more control variables.
2. Remove extreme outliers.
3. Use an alternative dependent variable.
4. Use an alternative explanatory variable.
5. Change the sample period.
6. Estimate the model on subgroups.
7. Use robust or clustered standard errors.
8. Compare OLS with another appropriate model.

Do not add robustness checks that are unrelated to the research question.

---

## Quality Checklist Before Finalizing

Before returning the paper, verify:

- [ ] The title states the relationship being studied.
- [ ] The abstract summarizes question, data, method, result, and implication.
- [ ] The introduction clearly states the research question.
- [ ] The literature review cites real academic sources.
- [ ] The methodology includes a numbered regression equation.
- [ ] Every variable in the equation is defined.
- [ ] The data section identifies data source, sample period, unit of observation, and number of observations.
- [ ] Empirical results are shown in a table.
- [ ] Coefficients are interpreted correctly.
- [ ] Claims are not stronger than the research design allows.
- [ ] Robustness checks are included or marked as TODO.
- [ ] The conclusion states result, explanation, contribution, limitations, and future research.
- [ ] References follow the required format.
- [ ] No fake coefficients, fake data, fake references, or fake results appear anywhere.

---

## Preferred Writing Style

Use:

- Formal academic tone
- Clear topic sentences
- Short paragraphs
- Precise econometric vocabulary
- Markdown headings and tables
- TODO markers for missing information

Avoid:

- Overly casual language
- Unsupported causal claims
- Decorative wording
- Long vague paragraphs
- Fake precision
- Inline-only regression reporting

---

## Minimal User Inputs Needed

When the user asks you to draft the paper, look for these inputs:

```text
Research question:
Dependent variable Y:
Main explanatory variable X:
Control variables:
Data source:
Sample period:
Unit of observation:
Regression output:
Reference list:
```

If some inputs are missing, proceed with TODO markers instead of asking repeated clarification questions.
