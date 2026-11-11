library(tidyverse)
library(ChainLadder)
library(lubridate)

set.seed(42)

# 1. GENERATE SYNTHETIC CLAIMS DATA
n_claims <- 1200

raw_claims_data <- tibble(
  claim_id       = paste0("CLM-", sprintf("%05d", 1:n_claims)),
  policy_id      = paste0("POL-", sprintf("%05d", sample(1:800, n_claims, replace = TRUE))),
  accident_date  = sample(seq(as.Date('2020/01/01'), as.Date('2024/12/31'), by = "day"), n_claims, replace = TRUE),
  report_lag     = rpois(n_claims, lambda = 45),
  reporting_date = accident_date + report_lag,
  paid_amount    = round(rlnorm(n_claims, meanlog = 8.5, sdlog = 1.1), 2)
)

# 2. DATA CLEANING & DEVELOPMENT PERIODS
cleaned_claims <- raw_claims_data %>%
  filter(reporting_date >= accident_date, paid_amount > 0) %>%
  mutate(
    accident_year = year(accident_date),
    report_year   = year(reporting_date),
    dev_year      = pmax(1, pmin(5, report_year - accident_year + 1))
  ) %>%
  filter(accident_year + dev_year - 1 <= 2024)

# 3. CONVERT TO CUMULATIVE TRIANGLE
incremental_df <- cleaned_claims %>%
  group_by(accident_year, dev_year) %>%
  summarise(total_paid = sum(paid_amount), .groups = "drop")

inc_tri <- as.triangle(incremental_df, origin = "accident_year", dev = "dev_year", value = "total_paid")
cum_tri <- incr2cum(inc_tri)

# 4. MACK CHAIN LADDER
mack_model   <- MackChainLadder(cum_tri, est.sigma = "Mack")
mack_summary <- summary(mack_model)

# 5. BORNHUETTER-FERGUSON CALCULATION
earned_premium <- c(`2020` = 12000000, `2021` = 13500000, `2022` = 15000000, `2023` = 16500000, `2024` = 18000000)
prior_ultimate <- earned_premium * 0.65

f_factors   <- mack_model$f
cdf         <- rev(cumprod(rev(c(f_factors, 1))))
latest_paid <- getLatestCumulative(cum_tri)
current_dev <- length(latest_paid):1

pct_developed  <- 1 / cdf[current_dev]
pct_unreported <- 1 - pct_developed
bf_ibnr        <- round(prior_ultimate * pct_unreported, 2)
bf_ultimate    <- round(latest_paid + bf_ibnr, 2)

# 6. EXPORT FINAL SCHEDULE
reserving_schedule <- tibble(
  Accident_Year  = rownames(cum_tri),
  Earned_Premium = earned_premium,
  Latest_Paid    = latest_paid,
  Mack_Ultimate  = round(mack_summary$ByOrigin$Ultimate, 2),
  Mack_IBNR      = round(mack_summary$ByOrigin$IBNR, 2),
  BF_Ultimate    = bf_ultimate,
  BF_IBNR        = bf_ibnr
)

write_csv(reserving_schedule, "actuarial_reserving_summary.csv")