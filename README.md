# Actuarial Claims Reserving and Loss Development Pipeline

An end-to-end actuarial data wrangling and loss reserving pipeline built in R. This project processes raw transaction-level policy claims registers into standard cumulative loss triangles, evaluates development factors (link ratios), and estimates Incurred But Not Reported (IBNR) liabilities using deterministic reserving methodologies.

---

# Technical Overview and Methodology

1. Automated Claims Data Wrangling (tidyverse):
- Processes transactional claims registers, standardizing accident and notification dates via lubridate.
- Filters data anomalies (such as negative claim disbursements and invalid lag periods) and categorizes development periods.
- Aggregates line-item records into incremental development matrices and formats them as triangular objects using ChainLadder::as.triangle().

2. Mack Chain Ladder Reserving:
- Calculates volume-weighted development factors across development years to quantify historical loss progression.
- Projects cumulative ultimate losses and extracts origin-year IBNR reserves.

3. Bornhuetter-Ferguson (BF) Method:
- Incorporates an a priori Expected Loss Ratio (ELR = 65%) against earned premium to stabilize volatile, recent accident years where early development is sparse.
- Computes the percentage of claims developed (1 / CDF) to determine the complement of credibility (1 - % Developed) applied to expected losses.

4. Reconciliation and Reporting:
- Compiles an executive summary comparing cumulative paid losses against Mack and BF ultimate reserves.
- Exports audited reserve schedules to structured CSV output for accounting disclosure.

---

# Output Comparison (Mack vs. Bornhuetter-Ferguson)

| Accident Year | Earned Premium | Latest Paid | Mack Ultimate | Mack IBNR | BF Ultimate | BF IBNR |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 2020 | 12,000,000 | Latest | Fully Developed | 0 | Fully Developed | 0 |
| 2021 | 13,500,000 | Latest | Projected | IBNR | Stabilized | BF IBNR |
| 2022 | 15,000,000 | Latest | Projected | IBNR | Stabilized | BF IBNR |
| 2023 | 16,500,000 | Latest | Projected | IBNR | Stabilized | BF IBNR |
| 2024 | 18,000,000 | Latest | Projected | High IBNR | ELR-Weighted | Balanced |

---

# File Structure
 claims_reserving_pipeline.R     # Complete pipeline: ingestion, triangle formation, and modeling
 actuarial_reserving_summary.csv # Generated executive summary of ultimate reserves and IBNR
.gitignore                      # Standard R project ignore file
 README.md                       # Documentation and methodology
