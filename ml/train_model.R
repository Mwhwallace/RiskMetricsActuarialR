# ML MODEL TRAINING - ACTUARIAL RISK SCORING
# This script trains and evaluates machine learning models for risk assessment

library(tidyverse)
library(tidymodels)
library(vetiver)
library(pins)

set.seed(123)

cat("Loading training data...\n")

# Load risk profiles data
risk_data <- read_csv("data/synthetic-risk-profiles.csv", show_col_types = FALSE)

# ==============================================================================
# DATA PREPARATION
# ==============================================================================

cat("Preparing features for modeling...\n")

# Select features for modeling
model_data <- risk_data |>
  select(
    # Target variable
    overall_risk_score,

    # Demographic features
    age, gender, marital_status, education_level, occupation_category,
    geographic_region, urban_rural,

    # Health features
    bmi, systolic_bp, cholesterol_ldl, smoking_status, alcohol_consumption,
    exercise_frequency, diabetes, hypertension, heart_disease,
    doctor_visits_annual, hospitalizations_5yr, num_prescriptions,

    # Financial features
    annual_income, credit_score, dti_ratio, num_late_payments_2yr,
    bankruptcy_history, years_current_employer, employment_gaps_5yr,

    # Behavioral features
    years_licensed, miles_driven_annual, accidents_5yr, tickets_5yr,
    dui_history, coverage_lapses_5yr,

    # Property features
    home_value, home_age_years, flood_zone, earthquake_zone,
    wildfire_risk, crime_rate_area
  ) |>
  drop_na()

cat(sprintf("  - Total observations: %d\n", nrow(model_data)))
cat(sprintf("  - Total features: %d\n", ncol(model_data) - 1))

# ==============================================================================
# TRAIN/TEST SPLIT
# ==============================================================================

cat("\nSplitting data...\n")

data_split <- initial_split(model_data, prop = 0.75, strata = overall_risk_score)
train_data <- training(data_split)
test_data <- testing(data_split)

cat(sprintf("  - Training set: %d observations\n", nrow(train_data)))
cat(sprintf("  - Test set: %d observations\n", nrow(test_data)))

# Cross-validation folds
cv_folds <- vfold_cv(train_data, v = 5, strata = overall_risk_score)

# ==============================================================================
# FEATURE ENGINEERING RECIPE
# ==============================================================================

cat("\nCreating feature engineering recipe...\n")

risk_recipe <- recipe(overall_risk_score ~ ., data = train_data) |>
  # Normalize numeric predictors
  step_normalize(all_numeric_predictors()) |>
  # One-hot encode categorical variables
  step_dummy(all_nominal_predictors()) |>
  # Remove zero variance predictors
  step_zv(all_predictors()) |>
  # Remove highly correlated features
  step_corr(all_numeric_predictors(), threshold = 0.9)

cat("  - Recipe created with normalization and encoding steps\n")

# ==============================================================================
# MODEL SPECIFICATIONS
# ==============================================================================

cat("\nDefining model specifications...\n")

# Linear regression model (baseline)
lm_spec <- linear_reg() |>
  set_engine("lm") |>
  set_mode("regression")

# Random forest model
rf_spec <- rand_forest(
  trees = 500,
  min_n = 10
) |>
  set_engine("ranger", importance = "impurity") |>
  set_mode("regression")

# Gradient boosting model
xgb_spec <- boost_tree(
  trees = 100,
  tree_depth = 6,
  learn_rate = 0.1,
  min_n = 5
) |>
  set_engine("xgboost") |>
  set_mode("regression")

cat("  - 3 model specifications created\n")

# ==============================================================================
# CREATE WORKFLOWS
# ==============================================================================

cat("\nCreating model workflows...\n")

lm_wf <- workflow() |>
  add_recipe(risk_recipe) |>
  add_model(lm_spec)

rf_wf <- workflow() |>
  add_recipe(risk_recipe) |>
  add_model(rf_spec)

xgb_wf <- workflow() |>
  add_recipe(risk_recipe) |>
  add_model(xgb_spec)

# ==============================================================================
# TRAIN AND EVALUATE MODELS
# ==============================================================================

cat("\nTraining models with cross-validation...\n")

# Define metrics
metrics <- metric_set(rmse, rsq, mae)

# Train linear model
cat("  - Training linear regression model...\n")
lm_fit <- fit_resamples(
  lm_wf,
  resamples = cv_folds,
  metrics = metrics,
  control = control_resamples(save_pred = TRUE)
)

# Train random forest
cat("  - Training random forest model...\n")
rf_fit <- fit_resamples(
  rf_wf,
  resamples = cv_folds,
  metrics = metrics,
  control = control_resamples(save_pred = TRUE)
)

# Train XGBoost
cat("  - Training XGBoost model...\n")
xgb_fit <- fit_resamples(
  xgb_wf,
  resamples = cv_folds,
  metrics = metrics,
  control = control_resamples(save_pred = TRUE)
)

# ==============================================================================
# COMPARE MODEL PERFORMANCE
# ==============================================================================

cat("\n" , rep("=", 70), "\n", sep = "")
cat("MODEL PERFORMANCE COMPARISON (Cross-Validation)\n")
cat(rep("=", 70), "\n", sep = "")

# Collect metrics
lm_metrics <- collect_metrics(lm_fit) |>
  mutate(model = "Linear Regression")

rf_metrics <- collect_metrics(rf_fit) |>
  mutate(model = "Random Forest")

xgb_metrics <- collect_metrics(xgb_fit) |>
  mutate(model = "XGBoost")

all_metrics <- bind_rows(lm_metrics, rf_metrics, xgb_metrics) |>
  select(model, .metric, mean, std_err) |>
  arrange(.metric, desc(mean))

print(all_metrics, n = 100)

# ==============================================================================
# SELECT BEST MODEL AND TRAIN ON FULL TRAINING SET
# ==============================================================================

cat("\nSelecting best model based on RMSE...\n")

best_model_name <- all_metrics |>
  filter(.metric == "rmse") |>
  slice_min(mean, n = 1) |>
  pull(model)

cat(sprintf("  - Best model: %s\n", best_model_name))

# Train final model on full training set
cat("\nTraining final model on complete training set...\n")

final_wf <- if (best_model_name == "Random Forest") {
  rf_wf
} else if (best_model_name == "XGBoost") {
  xgb_wf
} else {
  lm_wf
}

final_fit <- fit(final_wf, data = train_data)

# ==============================================================================
# EVALUATE ON TEST SET
# ==============================================================================

cat("\nEvaluating on test set...\n")

test_predictions <- predict(final_fit, test_data) |>
  bind_cols(test_data)

test_metrics <- test_predictions |>
  metrics(truth = overall_risk_score, estimate = .pred)

cat("\n", rep("=", 70), "\n", sep = "")
cat("TEST SET PERFORMANCE\n")
cat(rep("=", 70), "\n", sep = "")
print(test_metrics)

# ==============================================================================
# FEATURE IMPORTANCE (for tree-based models)
# ==============================================================================

if (best_model_name %in% c("Random Forest", "XGBoost")) {
  cat("\nExtracting feature importance...\n")

  importance_data <- extract_fit_engine(final_fit) |>
    vip::vi() |>
    slice_head(n = 20)

  cat("\nTop 20 Most Important Features:\n")
  print(importance_data, n = 20)

  # Save importance plot data
  write_csv(importance_data, "ml/feature_importance.csv")
  cat("  - Feature importance saved to ml/feature_importance.csv\n")
}

# ==============================================================================
# SAVE MODEL WITH VETIVER
# ==============================================================================

cat("\nSaving model with vetiver...\n")

# Create vetiver model
v_model <- vetiver_model(final_fit, "risk_score_model")

# Save model
vetiver_pin_write(board_folder("ml"), v_model)

cat("  - Model saved to ml/ directory\n")

# ==============================================================================
# MODEL VALIDATION PLOTS
# ==============================================================================

cat("\nGenerating validation plots...\n")

# Predicted vs Actual
validation_plot <- test_predictions |>
  ggplot(aes(x = overall_risk_score, y = .pred)) +
  geom_point(alpha = 0.4, color = "#1e3a5f") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "#8b2635", linewidth = 1) +
  geom_smooth(method = "lm", se = TRUE, color = "#2d7e8f", linewidth = 1.2) +
  labs(
    title = "Model Predictions vs Actual Risk Scores",
    subtitle = paste("Test Set Performance -", best_model_name),
    x = "Actual Risk Score",
    y = "Predicted Risk Score"
  ) +
  theme_minimal()

ggsave("ml/validation_plot.png", validation_plot, width = 8, height = 6, dpi = 300)
cat("  - Validation plot saved to ml/validation_plot.png\n")

# Residual plot
residual_plot <- test_predictions |>
  mutate(residual = overall_risk_score - .pred) |>
  ggplot(aes(x = .pred, y = residual)) +
  geom_point(alpha = 0.4, color = "#1e3a5f") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#8b2635", linewidth = 1) +
  geom_smooth(se = TRUE, color = "#2d7e8f", linewidth = 1.2) +
  labs(
    title = "Residual Plot",
    subtitle = "Checking for patterns in prediction errors",
    x = "Predicted Risk Score",
    y = "Residual (Actual - Predicted)"
  ) +
  theme_minimal()

ggsave("ml/residual_plot.png", residual_plot, width = 8, height = 6, dpi = 300)
cat("  - Residual plot saved to ml/residual_plot.png\n")

# ==============================================================================
# SAVE MODEL METADATA
# ==============================================================================

cat("\nSaving model metadata...\n")

model_metadata <- list(
  model_type = best_model_name,
  train_date = Sys.time(),
  n_train = nrow(train_data),
  n_test = nrow(test_data),
  n_features = ncol(model_data) - 1,
  test_rmse = test_metrics |> filter(.metric == "rmse") |> pull(.estimate),
  test_rsq = test_metrics |> filter(.metric == "rsq") |> pull(.estimate),
  test_mae = test_metrics |> filter(.metric == "mae") |> pull(.estimate)
)

saveRDS(model_metadata, "ml/model_metadata.rds")
write_csv(enframe(unlist(model_metadata)), "ml/model_metadata.csv")

cat("\n", rep("=", 70), "\n", sep = "")
cat("MODEL TRAINING COMPLETE\n")
cat(rep("=", 70), "\n\n", sep = "")

cat("Summary:\n")
cat(sprintf("  - Best model: %s\n", model_metadata$model_type))
cat(sprintf("  - Test RMSE: %.3f\n", model_metadata$test_rmse))
cat(sprintf("  - Test R²: %.3f\n", model_metadata$test_rsq))
cat(sprintf("  - Test MAE: %.3f\n", model_metadata$test_mae))
cat("\nModel artifacts saved in ml/ directory\n")
