# ACTUARIAL RISK ASSESSMENT API
# RESTful API for risk scoring and data access

library(plumber2)
library(tidyverse)
library(vetiver)
library(pins)
library(jsonlite)

# ==============================================================================
# LOAD DATA AND MODEL
# ==============================================================================

risk_profiles <- read_csv("data/synthetic-risk-profiles.csv", show_col_types = FALSE)
claims_history <- read_csv("data/synthetic-claims-history.csv", show_col_types = FALSE)

# Load trained model
model_board <- board_folder("ml")
v_model <- vetiver_pin_read(model_board, "risk_score_model")
model_metadata <- readRDS("ml/model_metadata.rds")

# ==============================================================================
# API DEFINITION
# ==============================================================================

#* @apiTitle RiskMetrics Analytics API
#* @apiDescription RESTful API for actuarial risk assessment and scoring
#* @apiVersion 1.0.0

# Health check endpoint
#* Check API health status
#* @get /health
function() {
  list(
    status = "healthy",
    timestamp = Sys.time(),
    model_version = "risk_score_model",
    model_type = model_metadata$model_type
  )
}

# Get sample risk profiles
#* Retrieve risk profile data
#* @param limit:int Maximum number of records to return (default: 100)
#* @param risk_category Risk category filter (optional)
#* @get /data/profiles
function(limit = 100, risk_category = NULL) {
  data <- risk_profiles

  if (!is.null(risk_category)) {
    data <- data |> filter(risk_category == !!risk_category)
  }

  data |>
    slice_head(n = as.integer(limit)) |>
    as.list()
}

# Get claims data
#* Retrieve claims history data
#* @param limit:int Maximum number of records to return (default: 100)
#* @param claim_type Claim type filter (optional)
#* @get /data/claims
function(limit = 100, claim_type = NULL) {
  data <- claims_history

  if (!is.null(claim_type)) {
    data <- data |> filter(claim_type == !!claim_type)
  }

  data |>
    arrange(desc(claim_date)) |>
    slice_head(n = as.integer(limit)) |>
    as.list()
}

# Get risk summary statistics
#* Get summary statistics by risk category
#* @get /data/summary
function() {
  risk_profiles |>
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
    ) |>
    as.list()
}

# Individual lookup
#* Get individual risk profile by ID
#* @param individual_id Individual identifier
#* @get /individual/<individual_id>
function(individual_id) {
  profile <- risk_profiles |>
    filter(individual_id == !!individual_id)

  if (nrow(profile) == 0) {
    stop("Individual not found")
  }

  # Get claims for this individual
  ind_claims <- claims_history |>
    filter(individual_id == !!individual_id) |>
    arrange(desc(claim_date))

  list(
    profile = as.list(profile),
    claims = as.list(ind_claims),
    claims_count = nrow(ind_claims)
  )
}

# Risk score prediction
#* Predict risk score for new individual
#* @param age:int Age in years
#* @param gender Gender (Male, Female, Non-Binary)
#* @param marital_status Marital status
#* @param education_level Education level
#* @param bmi:numeric Body mass index
#* @param systolic_bp:int Systolic blood pressure
#* @param smoking_status Smoking status (Never, Former, Current)
#* @param diabetes:int Has diabetes (0 or 1)
#* @param annual_income:numeric Annual income
#* @param credit_score:int Credit score (300-850)
#* @param dti_ratio:numeric Debt-to-income ratio
#* @param miles_driven_annual:numeric Annual miles driven
#* @param accidents_5yr:int Accidents in past 5 years
#* @param tickets_5yr:int Traffic tickets in past 5 years
#* @post /predict
function(
  age,
  gender = "Male",
  marital_status = "Single",
  education_level = "Bachelor",
  bmi = 25,
  systolic_bp = 120,
  smoking_status = "Never",
  diabetes = 0,
  annual_income = 75000,
  credit_score = 700,
  dti_ratio = 0.3,
  miles_driven_annual = 12000,
  accidents_5yr = 0,
  tickets_5yr = 0
) {
  # Validate inputs
  age <- as.integer(age)
  if (age < 18 || age > 90) {
    stop("Age must be between 18 and 90")
  }

  credit_score <- as.integer(credit_score)
  if (credit_score < 300 || credit_score > 850) {
    stop("Credit score must be between 300 and 850")
  }

  # Create input data
  new_data <- tibble(
    age = age,
    gender = gender,
    marital_status = marital_status,
    education_level = education_level,
    occupation_category = "Professional",
    geographic_region = "Northeast",
    urban_rural = "Suburban",
    bmi = as.numeric(bmi),
    systolic_bp = as.integer(systolic_bp),
    cholesterol_ldl = 100 + age * 0.5,
    smoking_status = smoking_status,
    alcohol_consumption = "Moderate",
    exercise_frequency = "Moderate",
    diabetes = as.integer(diabetes),
    hypertension = as.integer(systolic_bp > 140),
    heart_disease = 0,
    doctor_visits_annual = 2 + as.integer(diabetes) * 3,
    hospitalizations_5yr = as.integer(diabetes),
    num_prescriptions = as.integer(diabetes) * 2,
    annual_income = as.numeric(annual_income),
    credit_score = credit_score,
    dti_ratio = as.numeric(dti_ratio),
    num_late_payments_2yr = max(0, (750 - credit_score) / 50),
    bankruptcy_history = 0,
    years_current_employer = 5,
    employment_gaps_5yr = 0,
    years_licensed = max(0, age - 16),
    miles_driven_annual = as.numeric(miles_driven_annual),
    accidents_5yr = as.integer(accidents_5yr),
    tickets_5yr = as.integer(tickets_5yr),
    dui_history = 0,
    coverage_lapses_5yr = 0,
    home_value = annual_income * 3,
    home_age_years = 15,
    flood_zone = "None",
    earthquake_zone = "Low",
    wildfire_risk = "Low",
    crime_rate_area = "Moderate"
  )

  # Make prediction
  prediction <- predict(v_model, new_data)$.pred[1]

  # Calculate component scores
  health_score <- (bmi - 22) * 2 +
                 (systolic_bp - 120) * 0.3 +
                 (smoking_status == "Current") * 20 +
                 diabetes * 15
  health_score <- pmax(0, pmin(100, health_score))

  financial_score <- ((850 - credit_score) / 5.5) + (dti_ratio * 15)
  financial_score <- pmax(0, pmin(100, financial_score))

  driving_score <- (accidents_5yr * 15) + (tickets_5yr * 8) +
                  (miles_driven_annual / 200)
  driving_score <- pmax(0, pmin(100, driving_score))

  property_score <- 25  # Default moderate

  risk_category <- case_when(
    prediction < 20 ~ "Minimal Risk",
    prediction < 40 ~ "Low Risk",
    prediction < 60 ~ "Moderate Risk",
    prediction < 80 ~ "High Risk",
    TRUE ~ "Very High Risk"
  )

  list(
    overall_risk_score = round(prediction, 2),
    risk_category = risk_category,
    risk_breakdown = list(
      health = round(health_score, 2),
      financial = round(financial_score, 2),
      driving = round(driving_score, 2),
      property = round(property_score, 2)
    ),
    input_summary = list(
      age = age,
      credit_score = credit_score,
      annual_income = annual_income,
      bmi = bmi
    ),
    model_info = list(
      model_type = model_metadata$model_type,
      model_rmse = round(model_metadata$test_rmse, 3),
      model_r2 = round(model_metadata$test_rsq, 3)
    ),
    timestamp = Sys.time()
  )
}

# Batch prediction
#* Predict risk scores for multiple individuals
#* @param data JSON array of individual data
#* @post /predict/batch
#* @parser json
function(req) {
  input_data <- jsonlite::fromJSON(req$postBody)

  if (!is.data.frame(input_data)) {
    stop("Input must be a JSON array of objects")
  }

  # Ensure required columns exist
  required_cols <- c("age", "credit_score", "annual_income")
  missing_cols <- setdiff(required_cols, names(input_data))
  if (length(missing_cols) > 0) {
    stop(paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
  }

  # Add default values for missing optional columns
  defaults <- list(
    gender = "Male",
    marital_status = "Single",
    education_level = "Bachelor",
    occupation_category = "Professional",
    geographic_region = "Northeast",
    urban_rural = "Suburban",
    bmi = 25,
    systolic_bp = 120,
    cholesterol_ldl = 150,
    smoking_status = "Never",
    alcohol_consumption = "Moderate",
    exercise_frequency = "Moderate",
    diabetes = 0,
    hypertension = 0,
    heart_disease = 0,
    doctor_visits_annual = 2,
    hospitalizations_5yr = 0,
    num_prescriptions = 0,
    dti_ratio = 0.3,
    num_late_payments_2yr = 0,
    bankruptcy_history = 0,
    years_current_employer = 5,
    employment_gaps_5yr = 0,
    years_licensed = 10,
    miles_driven_annual = 12000,
    accidents_5yr = 0,
    tickets_5yr = 0,
    dui_history = 0,
    coverage_lapses_5yr = 0,
    home_value = 250000,
    home_age_years = 15,
    flood_zone = "None",
    earthquake_zone = "Low",
    wildfire_risk = "Low",
    crime_rate_area = "Moderate"
  )

  for (col in names(defaults)) {
    if (!(col %in% names(input_data))) {
      input_data[[col]] <- defaults[[col]]
    }
  }

  # Make predictions
  predictions <- predict(v_model, input_data)$.pred

  # Add risk categories
  risk_categories <- case_when(
    predictions < 20 ~ "Minimal Risk",
    predictions < 40 ~ "Low Risk",
    predictions < 60 ~ "Moderate Risk",
    predictions < 80 ~ "High Risk",
    TRUE ~ "Very High Risk"
  )

  list(
    predictions = predictions,
    risk_categories = risk_categories,
    count = length(predictions),
    avg_risk_score = mean(predictions),
    timestamp = Sys.time()
  )
}

# Model information
#* Get model metadata and performance metrics
#* @get /model-info
function() {
  list(
    model_type = model_metadata$model_type,
    train_date = model_metadata$train_date,
    performance = list(
      test_rmse = model_metadata$test_rmse,
      test_r2 = model_metadata$test_rsq,
      test_mae = model_metadata$test_mae
    ),
    training_data = list(
      n_train = model_metadata$n_train,
      n_test = model_metadata$n_test,
      n_features = model_metadata$n_features
    )
  )
}

# Risk distribution statistics
#* Get risk distribution across population
#* @get /analytics/distribution
function() {
  distribution <- risk_profiles |>
    count(risk_category) |>
    mutate(percentage = n / sum(n) * 100)

  list(
    total_individuals = nrow(risk_profiles),
    distribution = as.list(distribution),
    summary = list(
      high_risk_pct = sum(distribution$percentage[distribution$risk_category %in% c("High Risk", "Very High Risk")]),
      avg_risk_score = mean(risk_profiles$overall_risk_score),
      median_risk_score = median(risk_profiles$overall_risk_score)
    )
  )
}

# Claims statistics
#* Get claims summary statistics
#* @get /analytics/claims
function() {
  claims_by_type <- claims_history |>
    group_by(claim_type) |>
    summarise(
      count = n(),
      total_amount = sum(claim_amount),
      avg_amount = mean(claim_amount),
      .groups = "drop"
    )

  claims_by_status <- claims_history |>
    count(claim_status)

  list(
    total_claims = nrow(claims_history),
    total_amount = sum(claims_history$claim_amount),
    avg_claim_amount = mean(claims_history$claim_amount),
    by_type = as.list(claims_by_type),
    by_status = as.list(claims_by_status)
  )
}
