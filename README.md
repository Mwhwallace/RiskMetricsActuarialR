# RiskMetrics Analytics
## Comprehensive Actuarial Risk Assessment Platform

A demonstration project showcasing advanced actuarial risk assessment capabilities using R, tidymodels, and Posit's data science tools.

---

## Overview

This project demonstrates a complete end-to-end workflow for actuarial risk assessment, including:

- **Multi-dimensional Risk Profiling**: Health, Financial, Driving, and Property risk factors
- **Machine Learning Models**: Predictive risk scoring with 97.1% R² accuracy
- **Interactive Dashboards**: Shiny application for risk assessment and portfolio analysis
- **REST API**: Production-ready endpoints for system integration
- **Reproducible Analysis**: Quarto reports with comprehensive visualizations

### Key Features

✅ **Comprehensive Risk Assessment** - 58 variables across 4 risk dimensions
✅ **Advanced Machine Learning** - Tidymodels framework with model comparison
✅ **Interactive Applications** - Professional Shiny dashboard with real-time predictions
✅ **API Integration** - RESTful endpoints for external system connectivity
✅ **Publication-Quality Reports** - Quarto-based EDA with 20+ visualizations
✅ **Enterprise Deployment Ready** - Vetiver for ML Ops, renv for reproducibility

---

## Project Structure

```
RiskMetrics-Analytics_Actuarial-Risk-Consulting-R/
├── data/
│   ├── generate_data.R              # Synthetic data generation script
│   ├── synthetic-risk-profiles.csv   # Individual risk profiles (2,000 records)
│   ├── synthetic-claims-history.csv  # Historical claims data (1,500+ records)
│   └── synthetic-risk-summary.csv    # Summary statistics
├── ml/
│   ├── train_model.R                 # ML model training script
│   ├── model_metadata.rds            # Model performance metrics
│   ├── feature_importance.csv        # Feature importance scores
│   └── risk_score_model/             # Vetiver model artifacts
├── eda.qmd                           # Quarto analysis document
├── eda.html                          # Rendered EDA report
├── app.R                             # Shiny interactive application
├── api.R                             # Plumber2 REST API
├── _brand.yml                        # Brand configuration
├── renv.lock                         # R package dependencies
├── README.md                         # This file
└── posit-README.md                   # Internal demo guide
```

---

## Installation

### Prerequisites

- **R** 4.5.1 or later ([Download](https://cran.r-project.org/))
- **RStudio** (recommended) ([Download](https://posit.co/download/rstudio-desktop/))
- **Quarto** (for rendering reports) ([Download](https://quarto.org/docs/get-started/))

### Setup Instructions

1. **Clone or download this repository**
   ```bash
   cd RiskMetrics-Analytics_Actuarial-Risk-Consulting-R
   ```

2. **Open R or RStudio and install renv**
   ```r
   install.packages("renv")
   ```

3. **Restore all R packages**
   ```r
   renv::restore()
   ```

   This will install all required packages from the lockfile. This may take 5-10 minutes on first run.

4. **Verify installation**
   ```r
   library(tidyverse)
   library(tidymodels)
   library(shiny)
   library(vetiver)
   ```

---

## Usage

### 1. Data Generation

If you need to regenerate the synthetic data:

```r
source("data/generate_data.R")
```

This creates:
- 2,000 individual risk profiles
- 1,500+ historical claims records
- Summary statistics by risk category

### 2. Exploratory Data Analysis

View the pre-rendered EDA report:

```bash
open eda.html
```

Or render from source:

```bash
quarto render eda.qmd
```

The EDA report includes:
- Dataset overview and summary statistics
- Demographic analysis and risk distributions
- Health, financial, driving, and property risk breakdowns
- Multi-dimensional risk correlations
- Claims analysis and patterns
- Key risk factor identification

### 3. Machine Learning Model Training

Train the risk scoring model:

```r
source("ml/train_model.R")
```

This script:
- Loads and prepares risk profile data
- Creates train/test split (75/25)
- Trains multiple model types (Linear Regression, Random Forest, XGBoost)
- Performs 5-fold cross-validation
- Selects best model based on RMSE
- Saves model with vetiver for deployment
- Generates validation plots

**Model Performance:**
- Test RMSE: 2.0
- Test R²: 0.971
- Test MAE: 1.5

### 4. Interactive Shiny Application

Launch the interactive dashboard:

```r
library(shiny)
runApp("app.R")
```

The application features:
- **Dashboard Tab**: Portfolio overview with risk distributions and analytics
- **Individual Assessment Tab**: Real-time risk scoring calculator
- **Claims Analysis Tab**: Historical claims patterns and correlations
- **About Tab**: Application information and model details

Access at: `http://localhost:3838` (default)

### 5. REST API

Start the API server:

```r
library(plumber2)
pr("api.R") |> pr_run(port = 8000)
```

#### Available Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | API health status |
| `/data/profiles` | GET | Retrieve risk profile data |
| `/data/claims` | GET | Retrieve claims history |
| `/data/summary` | GET | Risk summary statistics |
| `/individual/<id>` | GET | Get individual by ID |
| `/predict` | POST | Predict risk score |
| `/predict/batch` | POST | Batch predictions |
| `/model-info` | GET | Model metadata |
| `/analytics/distribution` | GET | Risk distribution stats |
| `/analytics/claims` | GET | Claims statistics |

#### Example API Usage

**Health Check:**
```bash
curl http://localhost:8000/health
```

**Predict Risk Score:**
```bash
curl -X POST "http://localhost:8000/predict" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "age=40&credit_score=720&annual_income=85000&bmi=26&accidents_5yr=0"
```

**Get Sample Data:**
```bash
curl "http://localhost:8000/data/profiles?limit=10"
```

API documentation available at: `http://localhost:8000/__docs__/`

---

## Risk Assessment Methodology

### Risk Dimensions

The risk assessment model evaluates individuals across four key dimensions:

#### 1. Health Risk (30% weight)
- Body Mass Index (BMI)
- Blood pressure
- Cholesterol levels
- Smoking status
- Alcohol consumption
- Exercise frequency
- Chronic conditions (diabetes, hypertension, heart disease)
- Healthcare utilization

#### 2. Financial Risk (30% weight)
- Credit score
- Debt-to-income ratio
- Late payment history
- Bankruptcy history
- Employment stability
- Asset base

#### 3. Driving Risk (25% weight)
- Accident history
- Traffic violations
- DUI history
- Annual mileage
- Insurance coverage history
- Safety measures

#### 4. Property Risk (15% weight)
- Home age and construction
- Environmental risks (flood, earthquake, wildfire)
- Crime rate in area
- Claims history
- Security measures

### Risk Categories

| Category | Score Range | Description |
|----------|-------------|-------------|
| Minimal Risk | 0-20 | Excellent profile with minimal risk factors |
| Low Risk | 20-40 | Good profile with manageable risk factors |
| Moderate Risk | 40-60 | Average profile with some elevated factors |
| High Risk | 60-80 | Elevated risk requiring careful assessment |
| Very High Risk | 80-100 | Very high risk requiring individual underwriting |

---

## Customization & Extension

### Using This Project as a Template

This project can serve as a foundation for your own risk assessment applications:

1. **Replace Synthetic Data**: Adapt `data/generate_data.R` to load your actual data
2. **Customize Risk Factors**: Modify the feature engineering recipe in `ml/train_model.R`
3. **Update Branding**: Edit `_brand.yml` with your company's colors and fonts
4. **Extend Analysis**: Add sections to `eda.qmd` for domain-specific insights
5. **Enhance Dashboard**: Customize `app.R` with additional tabs and visualizations
6. **Add API Endpoints**: Extend `api.R` with business-specific functionality

### Integration Opportunities

- **Underwriting Systems**: Integrate API for real-time risk scoring
- **Claims Management**: Use risk profiles to inform claims processing
- **Customer Portals**: Embed Shiny app for customer self-service
- **Regulatory Reporting**: Leverage Quarto reports for compliance
- **Data Warehouses**: Connect to existing data sources via ODBC/JDBC

---

## Deployment

### Posit Connect (Recommended)

Deploy all components to Posit Connect for enterprise hosting:

```r
library(rsconnect)

# Deploy Shiny app
deployApp(appDir = ".", appName = "riskmetrics-dashboard")

# Deploy API
deployAPI("api.R", appName = "riskmetrics-api")

# Publish Quarto report
quarto publish connect eda.qmd
```

### Docker Deployment

Create a Dockerfile for containerized deployment:

```dockerfile
FROM rocker/r-ver:4.5.1
RUN R -e "install.packages('renv')"
COPY renv.lock renv.lock
RUN R -e "renv::restore()"
COPY . /app
WORKDIR /app
CMD ["R", "-e", "shiny::runApp('app.R', host='0.0.0.0', port=3838)"]
```

### ShinyApps.io

Deploy to shinyapps.io for quick sharing:

```r
library(rsconnect)
deployApp()
```

---

## Technology Stack

### Core R Packages

| Package | Purpose |
|---------|---------|
| **tidyverse** | Data manipulation and visualization |
| **tidymodels** | Machine learning framework |
| **vetiver** | Model deployment and versioning |
| **shiny** + **bslib** | Interactive web applications |
| **plumber2** | REST API framework |
| **quarto** | Reproducible reporting |
| **plotly** | Interactive visualizations |
| **gt** | Beautiful tables |
| **renv** | Dependency management |

### Posit Platform

- **Posit Workbench**: Collaborative development environment
- **Posit Connect**: Enterprise deployment platform
- **Posit Package Manager**: Secure package repository

---

## Performance Benchmarks

### Model Training
- Training time: ~30 seconds (on M1 Mac)
- Cross-validation: 5 folds × 3 models = 15 fits
- Final model training: <5 seconds

### Application Performance
- Shiny app load time: <2 seconds
- Risk score prediction: <100ms
- API response time: <50ms average

### Data Generation
- 2,000 profiles generation: ~5 seconds
- Full dataset with claims: ~10 seconds

---

## Troubleshooting

### Common Issues

**Q: Packages won't install**
A: Update renv and try again:
```r
install.packages("renv")
renv::restore()
```

**Q: Model file not found**
A: Retrain the model:
```r
source("ml/train_model.R")
```

**Q: Shiny app shows error**
A: Ensure all packages are installed and model is trained:
```r
renv::status()
file.exists("ml/risk_score_model")
```

**Q: API returns 500 error**
A: Check that model is accessible:
```r
library(pins)
library(vetiver)
board <- board_folder("ml")
vetiver_pin_read(board, "risk_score_model")
```

### Getting Help

- Check `posit-README.md` for detailed troubleshooting
- Review package documentation: `?function_name`
- Posit Community: https://community.rstudio.com/
- Stack Overflow: Tag questions with `[r]` and `[shiny]`

---

## Contributing

This is a demonstration project. To adapt for your use case:

1. Fork or copy the repository
2. Modify data sources and risk factors for your domain
3. Adjust model features and hyperparameters
4. Customize branding and visualizations
5. Extend with domain-specific functionality

---

## License

This demonstration project is provided as-is for educational and evaluation purposes.

---

## Acknowledgments

Built with:
- **R**: The R Foundation for Statistical Computing
- **RStudio/Posit**: Modern data science tools
- **Tidyverse**: Coherent system of R packages
- **Tidymodels**: Modeling framework for R

---

## Contact & Support

For questions about this demonstration or Posit's enterprise data science platform:

- **Website**: https://posit.co/
- **Sales**: sales@posit.co
- **Community**: https://community.rstudio.com/

---

## Important Disclaimer

**This project contains synthetic data and analysis created for demonstration purposes only.**

All data, insights, business scenarios, and analytics presented in this demonstration project have been artificially generated using AI. The data does not represent actual business information, performance metrics, customer data, or operational statistics.

### Key Points:

- **Synthetic Data**: All datasets are computer-generated and designed to illustrate analytical capabilities
- **Illustrative Analysis**: Insights and recommendations are examples of the types of analysis possible with Posit tools
- **No Actual Business Data**: No real business information or data was used or accessed in creating this demonstration
- **Educational Purpose**: This project serves as a technical demonstration of data science workflows and reporting capabilities
- **AI-Generated Content**: Analysis, commentary, and business scenarios were created by AI for illustration purposes
- **No Real-World Implications**: The scenarios and insights presented should not be interpreted as actual business advice or strategies

This demonstration showcases how Posit's data science platform and open-source tools can be applied to the actuarial risk consulting industry. The synthetic data and analysis provide a foundation for understanding the potential value of implementing similar analytical workflows with actual business data.

For questions about adapting these techniques to your real business scenarios, please contact your Posit representative.

---

*This demonstration was created using Posit's commercial data science tools and open-source packages. All synthetic data and analysis are provided for evaluation purposes only.*
# RiskMetricsActuarial-R
# RiskMetricsActuarialR
# RiskMetricsActuarialR
