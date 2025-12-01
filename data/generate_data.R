# SYNTHETIC DATA GENERATION SCRIPT
# This script generates artificial data for demonstration purposes only
# All data is computer-generated and does not represent real individuals

library(tidyverse)
library(lubridate)

set.seed(42)

# Number of synthetic individuals
n_individuals <- 2000

# ==============================================================================
# DEMOGRAPHIC DATA
# ==============================================================================

generate_demographics <- function(n) {
  tibble(
    individual_id = sprintf("IND%05d", 1:n),
    age = round(rnorm(n, mean = 42, sd = 15)),
    gender = sample(c("Male", "Female", "Non-Binary"), n,
                   replace = TRUE, prob = c(0.49, 0.49, 0.02)),
    marital_status = sample(c("Single", "Married", "Divorced", "Widowed"),
                           n, replace = TRUE, prob = c(0.35, 0.45, 0.15, 0.05)),
    education_level = sample(c("High School", "Associate", "Bachelor", "Master", "Doctorate"),
                            n, replace = TRUE, prob = c(0.25, 0.15, 0.35, 0.20, 0.05)),
    occupation_category = sample(
      c("Professional", "Management", "Service", "Sales", "Technical",
        "Administrative", "Labor", "Retired", "Student", "Unemployed"),
      n, replace = TRUE,
      prob = c(0.15, 0.12, 0.15, 0.10, 0.12, 0.10, 0.08, 0.08, 0.05, 0.05)
    ),
    geographic_region = sample(
      c("Northeast", "Southeast", "Midwest", "Southwest", "West", "Pacific"),
      n, replace = TRUE, prob = c(0.18, 0.22, 0.20, 0.15, 0.15, 0.10)
    ),
    urban_rural = sample(c("Urban", "Suburban", "Rural"),
                        n, replace = TRUE, prob = c(0.30, 0.50, 0.20))
  ) |>
    mutate(
      age = pmax(18, pmin(90, age))  # Clamp age between 18 and 90
    )
}

# ==============================================================================
# HEALTH RISK FACTORS
# ==============================================================================

generate_health_data <- function(demographics) {
  demographics |>
    mutate(
      # BMI with age correlation
      bmi = 22 + (age - 30) * 0.08 + rnorm(n(), 0, 3),
      bmi = pmax(16, pmin(45, bmi)),

      # Blood pressure (systolic)
      systolic_bp = 110 + (age - 30) * 0.5 + rnorm(n(), 0, 10),
      systolic_bp = pmax(90, pmin(180, systolic_bp)),

      # Cholesterol
      cholesterol_ldl = 100 + (age - 30) * 0.8 + rnorm(n(), 0, 25),
      cholesterol_ldl = pmax(50, pmin(250, cholesterol_ldl)),

      # Lifestyle factors
      smoking_status = case_when(
        age < 25 ~ sample(c("Never", "Former", "Current"), n(),
                         replace = TRUE, prob = c(0.70, 0.10, 0.20)),
        age < 50 ~ sample(c("Never", "Former", "Current"), n(),
                         replace = TRUE, prob = c(0.50, 0.30, 0.20)),
        TRUE ~ sample(c("Never", "Former", "Current"), n(),
                     replace = TRUE, prob = c(0.45, 0.40, 0.15))
      ),

      alcohol_consumption = sample(
        c("None", "Light", "Moderate", "Heavy"),
        n(), replace = TRUE, prob = c(0.25, 0.40, 0.25, 0.10)
      ),

      exercise_frequency = sample(
        c("Sedentary", "Light", "Moderate", "Active", "Very Active"),
        n(), replace = TRUE, prob = c(0.20, 0.25, 0.30, 0.15, 0.10)
      ),

      # Medical history
      diabetes = rbinom(n(), 1, plogis(-3 + 0.05 * age + 0.1 * (bmi - 25))),
      hypertension = rbinom(n(), 1, plogis(-4 + 0.06 * age + 0.05 * systolic_bp)),
      heart_disease = rbinom(n(), 1, plogis(-5 + 0.04 * age + 0.8 * diabetes)),

      # Healthcare utilization
      doctor_visits_annual = rpois(n(), lambda = 2 + 0.5 * (diabetes + hypertension + heart_disease)),
      hospitalizations_5yr = rpois(n(), lambda = 0.3 + 0.5 * (diabetes + hypertension + heart_disease)),

      # Prescription medications
      num_prescriptions = rpois(n(), lambda = 1 + age/20 + 2 * (diabetes + hypertension + heart_disease))
    )
}

# ==============================================================================
# FINANCIAL RISK FACTORS
# ==============================================================================

generate_financial_data <- function(demographics) {
  demographics |>
    mutate(
      # Income based on education and occupation
      annual_income = case_when(
        education_level == "High School" ~ rnorm(n(), 45000, 15000),
        education_level == "Associate" ~ rnorm(n(), 55000, 18000),
        education_level == "Bachelor" ~ rnorm(n(), 75000, 25000),
        education_level == "Master" ~ rnorm(n(), 95000, 30000),
        education_level == "Doctorate" ~ rnorm(n(), 120000, 40000),
        TRUE ~ 40000
      ),
      annual_income = pmax(20000, annual_income),

      # Adjust income by occupation
      annual_income = case_when(
        occupation_category %in% c("Management", "Professional") ~ annual_income * 1.3,
        occupation_category == "Retired" ~ annual_income * 0.4,
        occupation_category == "Student" ~ annual_income * 0.3,
        occupation_category == "Unemployed" ~ annual_income * 0.2,
        TRUE ~ annual_income
      ),

      # Credit score
      credit_score = rnorm(n(), 700, 80),
      credit_score = pmax(300, pmin(850, round(credit_score))),

      # Debt metrics
      total_debt = pmax(0, rnorm(n(), 50000, 40000)),
      mortgage_debt = if_else(age > 25, pmax(0, rnorm(n(), 180000, 120000)), 0),
      auto_loan_balance = pmax(0, rnorm(n(), 15000, 12000)),
      credit_card_debt = pmax(0, rnorm(n(), 8000, 6000)),

      # Debt-to-income ratio
      dti_ratio = (total_debt / 10) / (annual_income + 1),
      dti_ratio = pmin(2.0, dti_ratio),

      # Assets
      liquid_assets = pmax(0, rnorm(n(), annual_income * 0.5, annual_income * 0.4)),
      retirement_savings = pmax(0, (age - 25) * annual_income * 0.08 * runif(n(), 0.5, 1.5)),
      home_value = if_else(mortgage_debt > 0,
                          mortgage_debt * runif(n(), 1.2, 2.0), 0),

      # Payment history
      num_late_payments_2yr = rpois(n(), lambda = pmax(0, (750 - credit_score) / 100)),
      bankruptcy_history = rbinom(n(), 1, plogis(-4 + (700 - credit_score) / 150)),

      # Employment stability
      years_current_employer = pmax(0, rnorm(n(), 5, 3)),
      employment_gaps_5yr = rpois(n(), lambda = 0.3)
    )
}

# ==============================================================================
# BEHAVIORAL RISK FACTORS
# ==============================================================================

generate_behavioral_data <- function(demographics) {
  demographics |>
    mutate(
      # Driving record
      years_licensed = pmax(0, age - 16),
      miles_driven_annual = case_when(
        urban_rural == "Urban" ~ rnorm(n(), 8000, 3000),
        urban_rural == "Suburban" ~ rnorm(n(), 12000, 4000),
        urban_rural == "Rural" ~ rnorm(n(), 15000, 5000),
        TRUE ~ 10000
      ),
      miles_driven_annual = pmax(1000, miles_driven_annual),

      accidents_5yr = rpois(n(), lambda = 0.15 * miles_driven_annual / 10000),
      tickets_5yr = rpois(n(), lambda = 0.25 * miles_driven_annual / 10000),
      dui_history = rbinom(n(), 1, 0.03),

      # Insurance history
      years_insured = pmax(0, years_licensed - runif(n(), 0, 2)),
      coverage_lapses_5yr = rpois(n(), lambda = 0.2),
      prior_claims_count = rpois(n(), lambda = 0.4),

      # Risk-taking behavior indicators
      extreme_sports = rbinom(n(), 1, 0.08),
      frequent_travel = rbinom(n(), 1, 0.15),
      hazardous_hobby = rbinom(n(), 1, 0.05),

      # Safety measures
      security_system_home = rbinom(n(), 1, 0.45),
      alarm_system_vehicle = rbinom(n(), 1, 0.30),
      safety_course_completed = rbinom(n(), 1, 0.20)
    )
}

# ==============================================================================
# PROPERTY & ASSET RISK DATA
# ==============================================================================

generate_property_data <- function(demographics) {
  demographics |>
    mutate(
      # Home characteristics
      home_age_years = if_else(home_value > 0,
                              sample(1:80, n(), replace = TRUE), 0),
      home_sqft = if_else(home_value > 0,
                         rnorm(n(), 2000, 600), 0),
      construction_type = if_else(home_value > 0,
                                 sample(c("Wood Frame", "Brick", "Concrete", "Mixed"),
                                       n(), replace = TRUE,
                                       prob = c(0.50, 0.25, 0.15, 0.10)), NA_character_),
      roof_age_years = if_else(home_value > 0,
                              sample(1:30, n(), replace = TRUE), 0),

      # Location risk factors
      flood_zone = sample(c("None", "Moderate", "High"),
                         n(), replace = TRUE, prob = c(0.75, 0.15, 0.10)),
      earthquake_zone = sample(c("None", "Low", "Moderate", "High"),
                              n(), replace = TRUE, prob = c(0.60, 0.20, 0.15, 0.05)),
      wildfire_risk = sample(c("None", "Low", "Moderate", "High"),
                            n(), replace = TRUE, prob = c(0.65, 0.20, 0.10, 0.05)),
      crime_rate_area = sample(c("Low", "Moderate", "High"),
                              n(), replace = TRUE, prob = c(0.50, 0.35, 0.15)),

      # Property claims history
      property_claims_10yr = rpois(n(), lambda = 0.3),
      water_damage_claims = rpois(n(), lambda = 0.15),
      theft_claims = rpois(n(), lambda = 0.10)
    )
}

# ==============================================================================
# GENERATE COMPLETE RISK PROFILE
# ==============================================================================

cat("Generating synthetic risk assessment data...\n")

# Generate base demographics
demographics <- generate_demographics(n_individuals)

# Add all risk factor dimensions
complete_data <- demographics |>
  generate_health_data() |>
  generate_financial_data() |>
  generate_behavioral_data() |>
  generate_property_data()

# ==============================================================================
# CALCULATE COMPOSITE RISK SCORES
# ==============================================================================

complete_data <- complete_data |>
  mutate(
    # Health risk score (0-100, higher = more risk)
    health_risk_score = (
      (bmi - 22) * 2 +
      (systolic_bp - 120) * 0.3 +
      (cholesterol_ldl - 100) * 0.2 +
      (smoking_status == "Current") * 20 +
      (smoking_status == "Former") * 10 +
      (alcohol_consumption == "Heavy") * 15 +
      (exercise_frequency == "Sedentary") * 10 +
      diabetes * 15 +
      hypertension * 12 +
      heart_disease * 20 +
      hospitalizations_5yr * 5
    ),
    health_risk_score = pmax(0, pmin(100, health_risk_score)),

    # Financial risk score (0-100, higher = more risk)
    financial_risk_score = (
      ((850 - credit_score) / 5.5) +
      (dti_ratio * 15) +
      (num_late_payments_2yr * 5) +
      bankruptcy_history * 30 +
      (employment_gaps_5yr * 8) +
      (coverage_lapses_5yr * 6)
    ),
    financial_risk_score = pmax(0, pmin(100, financial_risk_score)),

    # Driving risk score (0-100, higher = more risk)
    driving_risk_score = (
      (accidents_5yr * 15) +
      (tickets_5yr * 8) +
      dui_history * 35 +
      (coverage_lapses_5yr * 10) +
      (miles_driven_annual / 200) -
      safety_course_completed * 5
    ),
    driving_risk_score = pmax(0, pmin(100, driving_risk_score)),

    # Property risk score (0-100, higher = more risk)
    property_risk_score = if_else(
      home_value > 0,
      (
        (home_age_years * 0.5) +
        (roof_age_years * 0.8) +
        (flood_zone == "High") * 20 +
        (flood_zone == "Moderate") * 10 +
        (earthquake_zone == "High") * 15 +
        (wildfire_risk == "High") * 18 +
        (crime_rate_area == "High") * 15 +
        (property_claims_10yr * 8) -
        security_system_home * 5
      ),
      0
    ),
    property_risk_score = pmax(0, pmin(100, property_risk_score)),

    # Overall composite risk score (weighted average)
    overall_risk_score = (
      health_risk_score * 0.30 +
      financial_risk_score * 0.30 +
      driving_risk_score * 0.25 +
      property_risk_score * 0.15
    ),

    # Risk classification
    risk_category = case_when(
      overall_risk_score < 20 ~ "Minimal Risk",
      overall_risk_score < 40 ~ "Low Risk",
      overall_risk_score < 60 ~ "Moderate Risk",
      overall_risk_score < 80 ~ "High Risk",
      TRUE ~ "Very High Risk"
    ),
    risk_category = factor(risk_category,
                          levels = c("Minimal Risk", "Low Risk", "Moderate Risk",
                                   "High Risk", "Very High Risk"))
  )

# ==============================================================================
# GENERATE CLAIMS HISTORY DATA
# ==============================================================================

# Probability of having a claim increases with risk score
claim_probability <- complete_data$overall_risk_score / 200 + 0.05

claims_data <- map_dfr(1:n_individuals, function(i) {
  n_claims <- rpois(1, claim_probability[i] * 3)

  if (n_claims == 0) return(NULL)

  tibble(
    individual_id = complete_data$individual_id[i],
    claim_date = sample(
      seq(today() - years(5), today(), by = "day"),
      n_claims, replace = TRUE
    ),
    claim_type = sample(
      c("Health", "Auto", "Property", "Life"),
      n_claims, replace = TRUE,
      prob = c(0.40, 0.30, 0.20, 0.10)
    ),
    claim_amount = pmax(100, rnorm(n_claims, 5000, 8000)),
    claim_status = sample(
      c("Paid", "Denied", "Pending"),
      n_claims, replace = TRUE,
      prob = c(0.75, 0.15, 0.10)
    )
  )
})

if (nrow(claims_data) > 0) {
  claims_data <- claims_data |>
    arrange(individual_id, claim_date) |>
    group_by(individual_id) |>
    mutate(claim_id = sprintf("%s_C%02d", individual_id, row_number())) |>
    ungroup() |>
    select(claim_id, everything())
}

# ==============================================================================
# SAVE DATA FILES
# ==============================================================================

cat("Saving synthetic data files...\n")

# Main risk profile data
write_csv(
  complete_data,
  "data/synthetic-risk-profiles.csv",
  na = ""
)

# Claims history
if (nrow(claims_data) > 0) {
  write_csv(
    claims_data,
    "data/synthetic-claims-history.csv",
    na = ""
  )
}

# Summary statistics by risk category
risk_summary <- complete_data |>
  group_by(risk_category) |>
  summarise(
    count = n(),
    avg_age = mean(age),
    avg_health_risk = mean(health_risk_score),
    avg_financial_risk = mean(financial_risk_score),
    avg_driving_risk = mean(driving_risk_score),
    avg_property_risk = mean(property_risk_score),
    avg_overall_risk = mean(overall_risk_score),
    .groups = "drop"
  )

write_csv(
  risk_summary,
  "data/synthetic-risk-summary.csv"
)

cat("\n✓ Data generation complete!\n")
cat(sprintf("  - Generated %d individual risk profiles\n", n_individuals))
cat(sprintf("  - Generated %d claims records\n", nrow(claims_data)))
cat("  - Risk category distribution:\n")
print(table(complete_data$risk_category))
