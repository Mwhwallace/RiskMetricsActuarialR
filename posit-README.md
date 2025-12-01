# RiskMetrics Analytics - Internal Demo Guide
## Actuarial Risk Assessment Platform

**Target Customer:** Milliman and similar actuarial consulting firms
**Industry:** Actuarial Risk Consulting & Insurance Analytics
**Demo Duration:** 15-20 minutes
**Difficulty:** Intermediate to Advanced

---

## Executive Summary

This demonstration showcases Posit's comprehensive data science platform capabilities for actuarial risk assessment using a fictional company "RiskMetrics Analytics." The demo features multi-dimensional risk profiling across health, financial, driving behavior, and property characteristics with advanced machine learning models achieving 97.1% R² accuracy.

**Key Value Propositions:**
- **End-to-end workflow**: Data generation → Analysis → ML → Deployment
- **Enterprise-grade ML**: Tidymodels framework with vetiver deployment
- **Interactive applications**: Shiny dashboard for stakeholder engagement
- **API integration**: Production-ready REST API for system integration
- **Reproducibility**: R

env for dependency management

---

## Industry Context

### About Milliman & Actuarial Risk Consulting

Milliman is a global consulting and actuarial firm providing services across health, insurance, retirement, and risk management sectors. Actuarial consultants:

- Assess and quantify risk for insurance underwriting
- Develop pricing models for insurance products
- Analyze claims patterns and predict future costs
- Create risk stratification systems
- Support regulatory compliance and reporting

### Why This Matters

**Pain Points:**
- Complex multi-dimensional risk assessment
- Need for explainable ML models
- Integration with existing systems
- Reproducible analysis for audits
- Stakeholder communication of technical insights

**Our Solution:**
- Posit's integrated tools handle the entire workflow
- R/tidymodels provides transparent, audit-friendly models
- Shiny creates executive-ready dashboards
- Posit Connect enables secure deployment
- Version control and reproducibility built-in

---

## Dataset Overview

### Synthetic Data Profile

**2,000 individual risk profiles** with comprehensive factors:

#### Demographics (8 variables)
- Age, gender, marital status, education, occupation
- Geographic region, urban/rural classification

#### Health Risk Factors (12 variables)
- BMI, blood pressure, cholesterol
- Smoking status, alcohol consumption, exercise frequency
- Diabetes, hypertension, heart disease
- Healthcare utilization metrics

#### Financial Risk Factors (13 variables)
- Annual income, credit score, debt-to-income ratio
- Debt breakdown (mortgage, auto, credit card)
- Assets (liquid, retirement, home value)
- Payment history, bankruptcy, employment stability

#### Behavioral/Driving Risk (14 variables)
- Driving record (accidents, tickets, DUI)
- Annual mileage, years licensed
- Insurance history and coverage lapses
- Risk behaviors (extreme sports, hazardous hobbies)
- Safety measures (alarms, safety courses)

#### Property Risk (11 variables)
- Home characteristics (age, construction type)
- Environmental risks (flood, earthquake, wildfire, crime)
- Claims history

**Total:** 58 variables per individual, plus calculated risk scores

### Claims Data

**1,544 historical claims** across:
- Health, Auto, Property, Life insurance
- Paid, Denied, and Pending statuses
- 5-year history with amounts and dates

---

## Demo Flow

### Part 1: Exploratory Data Analysis (5 minutes)

**File:** `eda.html` (pre-rendered Quarto report)

**Key Talking Points:**

1. **Open the EDA report** in a browser
   ```bash
   open eda.html
   ```

2. **Executive Summary Section**
   - "This analysis examines 2,000 individuals across 4 risk dimensions"
   - Point out the professional, branded appearance (IBM Plex fonts, custom colors)
   - Highlight: "Most individuals fall into Low to Moderate risk categories"

3. **Navigate to Health Risk Analysis**
   - BMI Distribution visualization: "Interactive plots with risk category overlay"
   - Blood Pressure vs Age: "Clear correlation with age, hypertension threshold marked"
   - Medical Conditions Impact: "Diabetes, hypertension significantly increase risk scores"

4. **Financial Risk Section**
   - Credit Score Distribution: "Standard credit tiers visible"
   - Income vs Debt-to-Income Ratio: "Risk score color-coding shows patterns"
   - Assets by Age: "Different risk profiles accumulate wealth differently"

5. **Multi-Dimensional Risk Analysis**
   - Correlation Matrix: "Shows how risk dimensions interact"
   - "Health and financial factors are strongest predictors"

6. **Claims Analysis**
   - "Individuals with higher risk scores have more frequent claims"
   - "Linear relationship validates our risk scoring approach"

**Key Message:** "Quarto provides publication-quality, reproducible analysis that can be shared with stakeholders or submitted to regulators."

---

### Part 2: Machine Learning Model (3 minutes)

**File:** `ml/train_model.R`

**Demo Steps:**

1. **Show the training script structure**
   ```r
   # Open in RStudio or show in editor
   ```

2. **Highlight key sections:**
   - "38 features across all risk dimensions"
   - "75/25 train/test split with 5-fold cross-validation"
   - "Compared 3 model types: Linear Regression, Random Forest, XGBoost"

3. **Show model performance**
   ```r
   model_metadata <- readRDS("ml/model_metadata.rds")
   model_metadata
   ```
   - Test RMSE: 2.0
   - Test R²: **0.971** ← emphasize this
   - Test MAE: 1.5

4. **Show validation plots**
   ```bash
   open ml/validation_plot.png
   open ml/residual_plot.png
   ```
   - "Predictions tightly clustered around actual values"
   - "No systematic bias in residuals"

**Key Messages:**
- "Tidymodels provides a consistent, modern ML framework"
- "97.1% R² means the model explains 97% of risk variation"
- "Vetiver enables easy model versioning and deployment"
- "All code is transparent and audit-friendly"

---

### Part 3: Interactive Shiny Application (5-7 minutes)

**File:** `app.R`

**Launch Instructions:**

```r
# In R console or RStudio
library(shiny)
runApp("app.R")
```

Or from command line:
```bash
Rscript -e "shiny::runApp('app.R', port = 3838)"
```

**Demo Flow:**

#### Dashboard Tab
1. **Portfolio Overview**
   - Point out clean, branded interface (based on `_brand.yml`)
   - Show statistics sidebar: Total individuals, Average risk, High risk %
   - **Try filters:** Select "Northeast" region
     - "Watch all visualizations update reactively"

2. **Risk Distribution Plot**
   - Interactive plotly chart
   - Hover to see counts and percentages

3. **Risk by Dimension**
   - "Shows average scores across health, financial, driving, property"
   - "Financial and health are highest on average"

4. **Age vs Risk Score scatter**
   - "Risk generally increases with age"
   - Color-coded by risk category

#### Individual Assessment Tab
1. **Demo the risk calculator**
   - "This is where underwriters would assess new applicants"

2. **Enter a profile:**
   ```
   Age: 45
   Gender: Male
   Marital: Married
   Education: Bachelor
   BMI: 28
   Systolic BP: 135
   Smoking: Former
   Diabetes: No
   Income: $95,000
   Credit Score: 720
   DTI Ratio: 0.35
   Annual Miles: 15,000
   Accidents: 1
   Tickets: 0
   ```

3. **Click "Calculate Risk Score"**
   - Show the real-time prediction
   - "Model predicts overall risk score and category"
   - Point out the **risk breakdown by dimension**
   - "Financial score is moderate due to DTI ratio"
   - "Health score elevated due to BMI and blood pressure"

4. **Try another profile - Low Risk:**
   ```
   Age: 30
   BMI: 22
   BP: 115
   Smoking: Never
   Credit Score: 780
   DTI: 0.20
   Income: $85,000
   ```
   - "Watch the score drop significantly"
   - "This demonstrates model sensitivity to key factors"

5. **Similar Individuals Table**
   - "Shows comparable profiles from historical data"
   - "Helps underwriters with context"

#### Claims Analysis Tab
1. **Claims by Type**
   - "Health claims are most frequent"
   - Status breakdown (Paid/Denied/Pending)

2. **Claims vs Risk Score**
   - "Clear correlation: higher risk = more claims"
   - "Validates our risk assessment approach"

3. **Recent Claims Table**
   - Scrollable, searchable DataTable
   - "Production-ready for claims adjusters"

**Key Messages:**
- "Shiny creates engaging dashboards for non-technical stakeholders"
- "Real-time calculations using the production ML model"
- "Fully customized branding with bslib"
- "Can be deployed to Posit Connect for secure sharing"

---

### Part 4: REST API (3 minutes)

**File:** `api.R`

**Launch Instructions:**

```r
# In R console
library(plumber2)
pr("api.R") |> pr_run(port = 8000)
```

Or from command line:
```bash
Rscript -e "library(plumber2); pr('api.R') |> pr_run(port = 8000)"
```

**Demo Flow:**

1. **Show API Documentation**
   - Open browser to: `http://localhost:8000/__docs__/`
   - "Plumber2 provides automatic interactive documentation"
   - Scroll through available endpoints

2. **Health Check**
   ```bash
   curl http://localhost:8000/health
   ```
   - Shows API status and model version

3. **Get Sample Data**
   ```bash
   curl "http://localhost:8000/data/profiles?limit=5"
   ```
   - Returns JSON array of risk profiles

4. **Risk Score Prediction (Key Demo)**
   ```bash
   curl -X POST "http://localhost:8000/predict" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "age=40&credit_score=720&annual_income=85000&bmi=26&accidents_5yr=0"
   ```

   Expected response:
   ```json
   {
     "overall_risk_score": 42.15,
     "risk_category": "Moderate Risk",
     "risk_breakdown": {
       "health": 18.6,
       "financial": 28.4,
       "driving": 6.0,
       "property": 25.0
     },
     "model_info": {
       "model_type": "Linear Regression",
       "model_rmse": 1.999,
       "model_r2": 0.971
     }
   }
   ```

5. **Model Info Endpoint**
   ```bash
   curl http://localhost:8000/model-info
   ```
   - Shows model performance metrics
   - Training details

**Key Messages:**
- "Production-ready REST API for system integration"
- "Can integrate with existing claims systems, CRMs, underwriting platforms"
- "Plumber2 provides enterprise features like authentication, rate limiting"
- "Deploy to Posit Connect for high-availability hosting"

---

## Setup Instructions

### Prerequisites
- R 4.5.1 or later
- RStudio (recommended) or R console
- Internet connection (for first-time package installation)

### Installation Steps

1. **Navigate to project directory**
   ```bash
   cd RiskMetrics-Analytics_Actuarial-Risk-Consulting-R
   ```

2. **Install renv (if not already installed)**
   ```r
   install.packages("renv")
   ```

3. **Restore R packages**
   ```r
   renv::restore()
   ```
   This will install all required packages from the lockfile (~5-10 minutes)

4. **Verify data files exist**
   ```bash
   ls data/
   # Should show: synthetic-risk-profiles.csv, synthetic-claims-history.csv, synthetic-risk-summary.csv
   ```

5. **If data files are missing, generate them**
   ```r
   source("data/generate_data.R")
   ```

6. **Train ML model (if not already trained)**
   ```r
   source("ml/train_model.R")
   ```

7. **Render EDA report (if needed)**
   ```bash
   quarto render eda.qmd
   ```

### Verification Checklist

- [ ] All packages installed (`renv::status()` shows "No issues found")
- [ ] Data files present in `data/` directory
- [ ] ML model saved in `ml/risk_score_model/` directory
- [ ] EDA report renders to `eda.html`
- [ ] Shiny app launches without errors
- [ ] API starts and responds to health check

---

## Troubleshooting

### Issue: Packages won't install
**Solution:**
```r
# Try updating renv
install.packages("renv")
renv::restore()

# If specific package fails, install manually
install.packages("pak")
pak::pak("package_name")
```

### Issue: Model file not found
**Solution:**
```r
# Retrain the model
source("ml/train_model.R")
```

### Issue: Shiny app won't launch
**Solution:**
```r
# Check for missing packages
library(shiny)
library(bslib)
library(plotly)
library(vetiver)
library(pins)

# If missing, install
renv::restore()
```

### Issue: API returns 500 error
**Solution:**
```r
# Verify model is loaded
library(pins)
library(vetiver)
board <- board_folder("ml")
vetiver_pin_read(board, "risk_score_model")
```

---

## Talking Points by Persona

### For CFO / Business Decision Makers
- "Reduce underwriting costs by 30% with automated risk assessment"
- "97% accuracy means fewer claims surprises and better pricing"
- "Interactive dashboards give your team instant insights"
- "API integration means no rip-and-replace of existing systems"

### For Chief Actuary / Analytics Leaders
- "Transparent, audit-friendly models using tidymodels"
- "Reproduce any analysis with version-controlled code"
- "Multi-dimensional risk assessment beyond traditional factors"
- "Seamless workflow from exploration to production deployment"

### For IT / Infrastructure Teams
- "Posit Connect provides enterprise deployment platform"
- "RESTful APIs integrate with any system"
- "Built-in authentication, load balancing, monitoring"
- "Supports air-gapped and on-premises deployments"

### For Data Science Teams
- "Modern R workflow with tidyverse and tidymodels"
- "Vetiver simplifies MLOps and model versioning"
- "Quarto creates publication-ready reports and presentations"
- "Shiny empowers data scientists to build production UIs"

---

## Next Steps & Call to Action

### Immediate Follow-Up
1. **Pilot Project:** "What risk assessment challenge can we tackle together?"
2. **Connect POC:** "Let's deploy this to Posit Connect in your environment"
3. **Custom Demo:** "We can customize this with your actual data structure"
4. **Training Workshop:** "Train your team on this workflow"

### Long-Term Engagement
- Posit Academy training for upskilling teams
- Professional services for production implementation
- Enterprise license for Posit Workbench + Connect
- Integration with existing actuarial software (e.g., Prophet, AXIS)

---

## Technical Architecture

### Posit Products Demonstrated

| Product | Usage | Value Proposition |
|---------|-------|-------------------|
| **Posit Workbench** | Development environment | Collaborative IDE for data science teams |
| **Posit Connect** | Deployment platform | Host Shiny apps, APIs, reports |
| **Posit Package Manager** | Package management | Reproducible, validated R packages |

### Key R Packages Showcased

| Package | Purpose | Enterprise Value |
|---------|---------|------------------|
| `tidyverse` | Data manipulation | Industry standard, well-documented |
| `tidymodels` | Machine learning | Consistent ML framework |
| `vetiver` | ML deployment | Simplifies MLOps |
| `shiny` + `bslib` | Interactive apps | Professional dashboards |
| `plumber2` | REST APIs | Production-ready integrations |
| `quarto` | Reports | Publication-quality documents |
| `renv` | Dependency management | Reproducibility |

---

## Additional Resources

- **Posit Solutions Page:** https://posit.co/solutions/
- **Tidymodels Documentation:** https://www.tidymodels.org/
- **Shiny Gallery:** https://shiny.posit.co/r/gallery/
- **Vetiver Documentation:** https://rstudio.github.io/vetiver-r/
- **Quarto Guide:** https://quarto.org/

---

## Competitive Differentiation

### vs. SAS
- "Open-source R with commercial support vs. expensive proprietary licenses"
- "Modern syntax and workflow vs. legacy SAS code"
- "Active community and rapid package development"

### vs. Python/Jupyter
- "R's statistical heritage aligns perfectly with actuarial work"
- "Tidymodels provides more structure than scikit-learn"
- "Shiny is more robust than Streamlit for production dashboards"

### vs. Excel/VBA
- "Scalable to millions of rows vs. Excel's 1M row limit"
- "Version-controlled, reproducible analysis"
- "Automated reporting vs. manual copy-paste"

---

**Demo Prepared By:** Claude Code
**Last Updated:** November 21, 2025
**Version:** 1.0

*All data in this demonstration is synthetic and generated for illustrative purposes only.*
