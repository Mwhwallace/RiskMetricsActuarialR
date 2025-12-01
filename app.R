# INTERACTIVE RISK ASSESSMENT APPLICATION
# Shiny application for actuarial risk scoring and analysis

library(shiny)
library(bslib)
library(tidyverse)
library(plotly)
library(scales)
library(vetiver)
library(pins)
library(bundle)
library(shinychat)
library(ellmer)

# ==============================================================================
# LOAD DATA AND MODEL
# ==============================================================================

risk_profiles <- read_csv("data/synthetic-risk-profiles.csv", show_col_types = FALSE)
claims_history <- read_csv("data/synthetic-claims-history.csv", show_col_types = FALSE)

# Load trained model
model_board <- board_folder("ml")
v_model <- vetiver_pin_read(model_board, "risk_score_model")

# Brand colors
brand_primary <- "#1e3a5f"
brand_secondary <- "#5a6c7d"
brand_success <- "#6b8e7f"
brand_warning <- "#d97706"
brand_danger <- "#8b2635"
brand_info <- "#2d7e8f"

risk_colors <- c(
  "Minimal Risk" = brand_success,
  "Low Risk" = brand_info,
  "Moderate Risk" = brand_warning,
  "High Risk" = "#b45309",
  "Very High Risk" = brand_danger
)

# ==============================================================================
# UI
# ==============================================================================

ui <- page_navbar(
  title = "RiskMetrics Analytics",
  theme = bs_theme(version = 5) |> bs_theme_update(primary = brand_primary),
  bg = brand_primary,

  # Dashboard Tab
  nav_panel(
    "Dashboard",
    layout_sidebar(
      sidebar = sidebar(
        width = 300,
        h4("Risk Portfolio Overview"),
        hr(),
        selectInput(
          "region_filter",
          "Geographic Region:",
          choices = c("All" = "all", unique(risk_profiles$geographic_region)),
          selected = "all"
        ),
        selectInput(
          "risk_filter",
          "Risk Category:",
          choices = c("All" = "all", levels(factor(risk_profiles$risk_category))),
          selected = "all"
        ),
        hr(),
        h5("Portfolio Statistics"),
        uiOutput("portfolio_stats")
      ),

      card(
        card_header("Risk Distribution"),
        plotlyOutput("risk_distribution_plot", height = "300px")
      ),

      layout_columns(
        col_widths = c(6, 6),
        card(
          card_header("Risk by Dimension"),
          plotlyOutput("risk_dimension_plot", height = "300px")
        ),
        card(
          card_header("Age vs Risk Score"),
          plotlyOutput("age_risk_plot", height = "300px")
        )
      ),

      card(
        card_header("Top Risk Indicators"),
        tableOutput("risk_indicators_table")
      )
    )
  ),

  # Individual Assessment Tab
  nav_panel(
    "Individual Assessment",
    layout_sidebar(
      sidebar = sidebar(
        width = 350,
        h4("Individual Risk Assessment"),
        p("Enter individual characteristics for risk scoring", style = "font-size: 0.9em; color: #5a6c7d;"),
        hr(),

        h5("Demographics"),
        numericInput("ind_age", "Age:", value = 35, min = 18, max = 90, step = 1),
        selectInput("ind_gender", "Gender:", choices = c("Male", "Female", "Non-Binary")),
        selectInput("ind_marital", "Marital Status:",
                   choices = c("Single", "Married", "Divorced", "Widowed")),
        selectInput("ind_education", "Education:",
                   choices = c("High School", "Associate", "Bachelor", "Master", "Doctorate")),

        hr(),
        h5("Health Factors"),
        numericInput("ind_bmi", "BMI:", value = 25, min = 15, max = 50, step = 0.1),
        numericInput("ind_bp", "Systolic BP:", value = 120, min = 80, max = 200, step = 1),
        selectInput("ind_smoking", "Smoking Status:",
                   choices = c("Never", "Former", "Current")),
        checkboxInput("ind_diabetes", "Diabetes", value = FALSE),

        hr(),
        h5("Financial Factors"),
        numericInput("ind_income", "Annual Income:", value = 75000, min = 0, step = 1000),
        numericInput("ind_credit", "Credit Score:", value = 700, min = 300, max = 850, step = 1),
        numericInput("ind_dti", "Debt-to-Income Ratio:", value = 0.3, min = 0, max = 2, step = 0.01),

        hr(),
        h5("Driving Factors"),
        numericInput("ind_miles", "Annual Miles:", value = 12000, min = 0, step = 1000),
        numericInput("ind_accidents", "Accidents (5yr):", value = 0, min = 0, max = 10, step = 1),
        numericInput("ind_tickets", "Tickets (5yr):", value = 0, min = 0, max = 10, step = 1),

        hr(),
        actionButton("calculate_risk", "Calculate Risk Score",
                    class = "btn-primary w-100", style = "margin-top: 10px;")
      ),

      card(
        card_header("Risk Assessment Results"),
        uiOutput("risk_score_display")
      ),

      card(
        card_header("Risk Factor Breakdown"),
        plotlyOutput("individual_risk_breakdown", height = "300px")
      ),

      card(
        card_header("Comparable Individuals"),
        tableOutput("similar_individuals_table")
      )
    )
  ),

  # Claims Analysis Tab
  nav_panel(
    "Claims Analysis",
    layout_columns(
      col_widths = c(6, 6),
      card(
        card_header("Claims by Type"),
        plotlyOutput("claims_type_plot", height = "350px")
      ),
      card(
        card_header("Claims vs Risk Score"),
        plotlyOutput("claims_risk_plot", height = "350px")
      )
    ),

    card(
      card_header("Recent Claims Activity"),
      DT::dataTableOutput("claims_table")
    )
  ),

  # Query Chat Tab
  nav_panel(
    "Query Chat",
    card(
      card_header("Ask Questions About Your Data"),
      p("Use natural language to query the risk profiles and claims data. Ask about trends, statistics, or specific insights.",
        style = "color: #5a6c7d; margin-bottom: 10px;"),
      
      # Suggested questions
      div(
        style = "margin-bottom: 20px; padding: 15px; background: #f8f9fa; border-radius: 5px;",
        h6("Try asking:", style = "margin-bottom: 10px; color: #1e3a5f;"),
        div(
          style = "display: flex; flex-wrap: wrap; gap: 8px;",
          actionLink("suggest_1", "What's the average risk score by region?", 
                    style = "padding: 6px 12px; background: white; border: 1px solid #dee2e6; border-radius: 4px; font-size: 0.9em;"),
          actionLink("suggest_2", "How many high-risk individuals have diabetes?",
                    style = "padding: 6px 12px; background: white; border: 1px solid #dee2e6; border-radius: 4px; font-size: 0.9em;"),
          actionLink("suggest_3", "What's the total value of paid claims by type?",
                    style = "padding: 6px 12px; background: white; border: 1px solid #dee2e6; border-radius: 4px; font-size: 0.9em;"),
          actionLink("suggest_4", "Compare risk scores for smokers vs non-smokers",
                    style = "padding: 6px 12px; background: white; border: 1px solid #dee2e6; border-radius: 4px; font-size: 0.9em;"),
          actionLink("suggest_5", "What factors correlate most with high risk scores?",
                    style = "padding: 6px 12px; background: white; border: 1px solid #dee2e6; border-radius: 4px; font-size: 0.9em;"),
          actionLink("suggest_6", "Show me claims statistics for individuals over 50",
                    style = "padding: 6px 12px; background: white; border: 1px solid #dee2e6; border-radius: 4px; font-size: 0.9em;")
        )
      ),
      
      chat_ui("data_chat", height = "500px")
    )
  ),

  # About Tab
  nav_panel(
    "About",
    card(
      card_header("About This Application"),
      markdown("
## RiskMetrics Analytics - Actuarial Risk Assessment Platform

This interactive application demonstrates comprehensive actuarial risk assessment capabilities
using advanced analytics and machine learning.

### Features

- **Risk Portfolio Dashboard**: Overview of risk distribution and key metrics
- **Individual Assessment**: Interactive risk scoring for new applicants
- **Claims Analysis**: Historical claims patterns and predictions
- **Multi-dimensional Risk**: Health, financial, driving, and property factors

### Model Performance

The predictive model achieves:
- **R² = 0.971** on test data
- **RMSE = 2.0** risk score points
- **MAE = 1.5** risk score points

### Data

All data in this application is **synthetic** and generated for demonstration purposes only.

### Technology Stack

- **R & Tidyverse**: Data processing and analysis
- **Tidymodels**: Machine learning framework
- **Shiny & bslib**: Interactive web application
- **Plotly**: Interactive visualizations
- **Vetiver**: Model deployment and versioning
")
    )
  )
)

# ==============================================================================
# SERVER
# ==============================================================================

server <- function(input, output, session) {

  # Initialize chat with system prompt about the data
  chat <- ellmer::chat_aws_bedrock(
    model = "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
    system_prompt = paste0(
      "You are a helpful actuarial data analyst assistant for RiskMetrics Analytics. ",
      "You have access to two datasets:\n\n",
      "1. **Risk Profiles Dataset** (", nrow(risk_profiles), " individuals) with columns:\n",
      "   - Demographics: age, gender, marital_status, education_level, occupation_category, geographic_region\n",
      "   - Health: bmi, systolic_bp, cholesterol_ldl, smoking_status, diabetes, hypertension, heart_disease\n",
      "   - Financial: annual_income, credit_score, dti_ratio, bankruptcy_history\n",
      "   - Driving: years_licensed, miles_driven_annual, accidents_5yr, tickets_5yr, dui_history\n",
      "   - Property: home_value, home_age_years, flood_zone, earthquake_zone, wildfire_risk\n",
      "   - Risk Scores: health_risk_score, financial_risk_score, driving_risk_score, property_risk_score, overall_risk_score\n",
      "   - Risk Category: Minimal Risk, Low Risk, Moderate Risk, High Risk, Very High Risk\n\n",
      "2. **Claims History Dataset** (", nrow(claims_history), " claims) with columns:\n",
      "   - claim_id, individual_id, claim_date, claim_type, claim_amount, claim_status\n\n",
      "When answering questions:\n",
      "- Provide clear, professional responses with specific numbers and insights\n",
      "- Use bullet points or tables when appropriate\n",
      "- Reference relevant statistics from the data\n",
      "- Explain actuarial concepts in accessible terms\n",
      "- Format numbers appropriately (percentages, currency, etc.)\n",
      "- If you need to calculate something, explain your methodology\n\n",
      "The data is synthetic and for demonstration purposes only."
    )
  )
  
  # Register tool for querying risk profiles
  query_risk_profiles <- function(query_type = "summary", 
                                   filter_column = NULL, 
                                   filter_value = NULL,
                                   group_by = NULL,
                                   metric = NULL) {
    
    data <- risk_profiles
    
    # Apply filters if specified
    if (!is.null(filter_column) && !is.null(filter_value)) {
      if (filter_column %in% names(data)) {
        data <- data |> filter(.data[[filter_column]] == filter_value)
      }
    }
    
    # Return results based on query type
    if (query_type == "summary") {
      list(
        total_individuals = nrow(data),
        avg_risk_score = mean(data$overall_risk_score),
        avg_age = mean(data$age),
        avg_income = mean(data$annual_income),
        high_risk_pct = mean(data$risk_category %in% c("High Risk", "Very High Risk"))
      )
    } else if (query_type == "aggregate" && !is.null(group_by) && !is.null(metric)) {
      if (group_by %in% names(data) && metric %in% names(data)) {
        result <- data |>
          group_by(.data[[group_by]]) |>
          summarise(
            count = n(),
            avg_value = mean(.data[[metric]], na.rm = TRUE),
            .groups = "drop"
          ) |>
          head(10)
        as.list(result)
      } else {
        list(error = "Invalid column names")
      }
    } else {
      # Return sample of filtered data
      data |> 
        select(individual_id, age, gender, risk_category, overall_risk_score, 
               annual_income, credit_score) |>
        head(10) |>
        as.list()
    }
  }
  
  chat$register_tool(tool(
    query_risk_profiles,
    "Query the risk profiles dataset. Can filter, aggregate, or get summary statistics.",
    query_type = type_enum(
      "Type of query to perform",
      values = c("summary", "filter", "aggregate")
    ),
    filter_column = type_string("Column name to filter on", required = FALSE),
    filter_value = type_string("Value to filter for", required = FALSE),
    group_by = type_string("Column to group by for aggregation", required = FALSE),
    metric = type_string("Metric column to aggregate", required = FALSE)
  ))
  
  # Register tool for querying claims
  query_claims <- function(query_type = "summary",
                           individual_id = NULL,
                           claim_type = NULL) {
    
    data <- claims_history
    
    if (query_type == "summary") {
      list(
        total_claims = nrow(data),
        total_amount = sum(data$claim_amount),
        avg_claim = mean(data$claim_amount),
        paid_claims = sum(data$claim_status == "Paid"),
        denied_claims = sum(data$claim_status == "Denied"),
        pending_claims = sum(data$claim_status == "Pending")
      )
    } else if (query_type == "by_type") {
      result <- data |>
        group_by(claim_type) |>
        summarise(
          count = n(),
          total_amount = sum(claim_amount),
          avg_amount = mean(claim_amount),
          .groups = "drop"
        )
      as.list(result)
    } else if (query_type == "by_individual" && !is.null(individual_id)) {
      result <- data |>
        filter(individual_id == !!individual_id) |>
        select(claim_id, claim_date, claim_type, claim_amount, claim_status) |>
        head(20)
      as.list(result)
    } else {
      list(error = "Invalid query parameters")
    }
  }
  
  chat$register_tool(tool(
    query_claims,
    "Query the claims history dataset. Can get summaries, breakdowns by type, or claims for specific individuals.",
    query_type = type_enum(
      "Type of query",
      values = c("summary", "by_type", "by_individual")
    ),
    individual_id = type_string("Individual ID to query claims for", required = FALSE),
    claim_type = type_string("Filter by claim type", required = FALSE)
  ))
  
  # Handle chat interactions
  observeEvent(input$data_chat_user_input, {
    stream <- chat$stream_async(input$data_chat_user_input)
    chat_append("data_chat", stream)
  })
  
  # Handle suggested question clicks
  observeEvent(input$suggest_1, {
    stream <- chat$stream_async("What's the average risk score by region?")
    chat_append("data_chat", stream)
  })
  
  observeEvent(input$suggest_2, {
    stream <- chat$stream_async("How many high-risk individuals have diabetes?")
    chat_append("data_chat", stream)
  })
  
  observeEvent(input$suggest_3, {
    stream <- chat$stream_async("What's the total value of paid claims by type?")
    chat_append("data_chat", stream)
  })
  
  observeEvent(input$suggest_4, {
    stream <- chat$stream_async("Compare risk scores for smokers vs non-smokers")
    chat_append("data_chat", stream)
  })
  
  observeEvent(input$suggest_5, {
    stream <- chat$stream_async("What factors correlate most with high risk scores?")
    chat_append("data_chat", stream)
  })
  
  observeEvent(input$suggest_6, {
    stream <- chat$stream_async("Show me claims statistics for individuals over 50")
    chat_append("data_chat", stream)
  })

  # Reactive filtered data
  filtered_data <- reactive({
    data <- risk_profiles

    if (input$region_filter != "all") {
      data <- data |> filter(geographic_region == input$region_filter)
    }

    if (input$risk_filter != "all") {
      data <- data |> filter(risk_category == input$risk_filter)
    }

    data
  })

  # Portfolio statistics
  output$portfolio_stats <- renderUI({
    data <- filtered_data()

    tagList(
      div(
        style = "background: #f8f9fa; padding: 10px; border-radius: 5px; margin-bottom: 10px;",
        strong("Total Individuals:"),
        br(),
        h4(comma(nrow(data)), style = "color: #1e3a5f; margin: 5px 0;")
      ),
      div(
        style = "background: #f8f9fa; padding: 10px; border-radius: 5px; margin-bottom: 10px;",
        strong("Average Risk Score:"),
        br(),
        h4(number(mean(data$overall_risk_score), accuracy = 0.1),
           style = "color: #1e3a5f; margin: 5px 0;")
      ),
      div(
        style = "background: #f8f9fa; padding: 10px; border-radius: 5px;",
        strong("High Risk %:"),
        br(),
        h4(percent(mean(data$risk_category %in% c("High Risk", "Very High Risk")), accuracy = 0.1),
           style = "color: #8b2635; margin: 5px 0;")
      )
    )
  })

  # Risk distribution plot
  output$risk_distribution_plot <- renderPlotly({
    data <- filtered_data()

    risk_dist <- data |>
      count(risk_category) |>
      mutate(pct = n / sum(n))

    plot_ly(risk_dist,
            x = ~risk_category,
            y = ~n,
            type = "bar",
            marker = list(color = risk_colors[risk_dist$risk_category]),
            text = ~paste0(comma(n), " (", percent(pct, accuracy = 0.1), ")"),
            hovertemplate = "%{x}<br>%{text}<extra></extra>") |>
      layout(
        xaxis = list(title = ""),
        yaxis = list(title = "Count"),
        showlegend = FALSE,
        margin = list(l = 50, r = 20, t = 20, b = 80)
      )
  })

  # Risk dimension plot
  output$risk_dimension_plot <- renderPlotly({
    data <- filtered_data()

    dimension_avg <- data |>
      summarise(
        Health = mean(health_risk_score),
        Financial = mean(financial_risk_score),
        Driving = mean(driving_risk_score),
        Property = mean(property_risk_score)
      ) |>
      pivot_longer(everything(), names_to = "dimension", values_to = "score")

    plot_ly(dimension_avg,
            x = ~dimension,
            y = ~score,
            type = "bar",
            marker = list(color = brand_primary),
            text = ~number(score, accuracy = 0.1),
            textposition = "outside",
            hovertemplate = "%{x}<br>Score: %{y:.1f}<extra></extra>") |>
      layout(
        xaxis = list(title = ""),
        yaxis = list(title = "Average Score", range = c(0, 100)),
        showlegend = FALSE,
        margin = list(l = 50, r = 20, t = 20, b = 50)
      )
  })

  # Age vs risk plot
  output$age_risk_plot <- renderPlotly({
    data <- filtered_data()
    sample_size <- min(500, nrow(data))
    if (nrow(data) > sample_size) {
      data <- data |> slice_sample(n = sample_size)
    }

    plot_ly(data,
            x = ~age,
            y = ~overall_risk_score,
            color = ~risk_category,
            colors = risk_colors,
            type = "scatter",
            mode = "markers",
            marker = list(size = 6, opacity = 0.6),
            hovertemplate = "Age: %{x}<br>Risk: %{y:.1f}<extra></extra>") |>
      layout(
        xaxis = list(title = "Age"),
        yaxis = list(title = "Overall Risk Score"),
        legend = list(orientation = "h", y = -0.2),
        margin = list(l = 50, r = 20, t = 20, b = 80)
      )
  })

  # Risk indicators table
  output$risk_indicators_table <- renderTable({
    data <- filtered_data()

    tibble(
      Indicator = c(
        "Avg Credit Score",
        "Avg BMI",
        "Diabetes Prevalence",
        "Avg Annual Income",
        "Accidents (5yr avg)",
        "High Risk Properties"
      ),
      Value = c(
        comma(round(mean(data$credit_score))),
        number(mean(data$bmi), accuracy = 0.1),
        percent(mean(data$diabetes), accuracy = 0.1),
        dollar(mean(data$annual_income)),
        number(mean(data$accidents_5yr), accuracy = 0.01),
        percent(mean(data$property_risk_score > 60), accuracy = 0.1)
      )
    )
  })

  # Individual risk calculation
  individual_risk <- eventReactive(input$calculate_risk, {
    # Create input data frame matching model expectations
    new_data <- tibble(
      age = input$ind_age,
      gender = input$ind_gender,
      marital_status = input$ind_marital,
      education_level = input$ind_education,
      occupation_category = "Professional",  # Default
      geographic_region = "Northeast",  # Default
      urban_rural = "Suburban",  # Default
      bmi = input$ind_bmi,
      systolic_bp = input$ind_bp,
      cholesterol_ldl = 100 + input$ind_age * 0.5,  # Estimated
      smoking_status = input$ind_smoking,
      alcohol_consumption = "Moderate",  # Default
      exercise_frequency = "Moderate",  # Default
      diabetes = as.numeric(input$ind_diabetes),
      hypertension = as.numeric(input$ind_bp > 140),
      heart_disease = 0,
      doctor_visits_annual = 2 + input$ind_diabetes * 3,
      hospitalizations_5yr = input$ind_diabetes,
      num_prescriptions = input$ind_diabetes * 2,
      annual_income = input$ind_income,
      credit_score = input$ind_credit,
      dti_ratio = input$ind_dti,
      num_late_payments_2yr = max(0, (750 - input$ind_credit) / 50),
      bankruptcy_history = 0,
      years_current_employer = 5,
      employment_gaps_5yr = 0,
      years_licensed = max(0, input$ind_age - 16),
      miles_driven_annual = input$ind_miles,
      accidents_5yr = input$ind_accidents,
      tickets_5yr = input$ind_tickets,
      dui_history = 0,
      coverage_lapses_5yr = 0,
      home_value = input$ind_income * 3,
      home_age_years = 15,
      flood_zone = "None",
      earthquake_zone = "Low",
      wildfire_risk = "Low",
      crime_rate_area = "Moderate"
    )

    # Calculate component scores (simplified)
    health_score <- (input$ind_bmi - 22) * 2 +
                   (input$ind_bp - 120) * 0.3 +
                   (input$ind_smoking == "Current") * 20 +
                   input$ind_diabetes * 15
    health_score <- pmax(0, pmin(100, health_score))

    financial_score <- ((850 - input$ind_credit) / 5.5) + (input$ind_dti * 15)
    financial_score <- pmax(0, pmin(100, financial_score))

    driving_score <- (input$ind_accidents * 15) + (input$ind_tickets * 8) +
                    (input$ind_miles / 200)
    driving_score <- pmax(0, pmin(100, driving_score))

    property_score <- 25  # Default moderate

    # Calculate overall risk score as weighted average of components
    # Using weights: Health 30%, Financial 25%, Driving 25%, Property 20%
    prediction <- (health_score * 0.30 + 
                   financial_score * 0.25 + 
                   driving_score * 0.25 + 
                   property_score * 0.20)

    list(
      overall = prediction,
      health = health_score,
      financial = financial_score,
      driving = driving_score,
      property = property_score,
      category = case_when(
        prediction < 20 ~ "Minimal Risk",
        prediction < 40 ~ "Low Risk",
        prediction < 60 ~ "Moderate Risk",
        prediction < 80 ~ "High Risk",
        TRUE ~ "Very High Risk"
      )
    )
  })

  # Risk score display
  output$risk_score_display <- renderUI({
    req(individual_risk())
    risk <- individual_risk()

    color <- case_when(
      risk$overall < 40 ~ brand_success,
      risk$overall < 60 ~ brand_warning,
      TRUE ~ brand_danger
    )

    tagList(
      div(
        style = paste0("text-align: center; padding: 30px; background: linear-gradient(135deg, ",
                      color, " 0%, ", color, "dd 100%); border-radius: 10px; color: white;"),
        h2("Overall Risk Score", style = "margin: 0; font-weight: 300;"),
        h1(number(risk$overall, accuracy = 0.1),
           style = "margin: 10px 0; font-size: 4em; font-weight: bold;"),
        h3(risk$category, style = "margin: 0; font-weight: 400;")
      ),
      div(
        style = "margin-top: 20px; padding: 15px; background: #f8f9fa; border-radius: 5px;",
        h5("Risk Classification"),
        p(
          case_when(
            risk$category == "Minimal Risk" ~ "Excellent profile with minimal risk factors. Standard coverage recommended.",
            risk$category == "Low Risk" ~ "Good profile with manageable risk factors. Competitive rates available.",
            risk$category == "Moderate Risk" ~ "Average profile with some elevated risk factors. Standard coverage with monitoring.",
            risk$category == "High Risk" ~ "Elevated risk profile requiring careful assessment. Specialized coverage may be needed.",
            TRUE ~ "Very high risk profile. Individual underwriting required."
          ),
          style = "margin: 10px 0; color: #5a6c7d;"
        )
      )
    )
  })

  # Individual risk breakdown
  output$individual_risk_breakdown <- renderPlotly({
    req(individual_risk())
    risk <- individual_risk()

    breakdown <- tibble(
      dimension = c("Health", "Financial", "Driving", "Property"),
      score = c(risk$health, risk$financial, risk$driving, risk$property)
    )

    plot_ly(breakdown,
            x = ~dimension,
            y = ~score,
            type = "bar",
            marker = list(
              color = ~score,
              colorscale = list(c(0, brand_success), c(0.5, brand_warning), c(1, brand_danger)),
              cmin = 0,
              cmax = 100
            ),
            text = ~number(score, accuracy = 0.1),
            textposition = "outside",
            hovertemplate = "%{x}<br>Score: %{y:.1f}<extra></extra>") |>
      layout(
        xaxis = list(title = ""),
        yaxis = list(title = "Risk Score", range = c(0, 100)),
        showlegend = FALSE
      )
  })

  # Similar individuals table
  output$similar_individuals_table <- renderTable({
    req(individual_risk())
    risk <- individual_risk()

    risk_profiles |>
      mutate(
        age_diff = abs(age - input$ind_age),
        credit_diff = abs(credit_score - input$ind_credit),
        similarity = 1 / (1 + age_diff * 0.1 + credit_diff * 0.01)
      ) |>
      arrange(desc(similarity)) |>
      slice_head(n = 5) |>
      select(Age = age, `Credit Score` = credit_score,
             `Risk Score` = overall_risk_score, Category = risk_category) |>
      mutate(`Risk Score` = round(`Risk Score`, 1))
  })

  # Claims by type plot
  output$claims_type_plot <- renderPlotly({
    claims_summary <- claims_history |>
      group_by(claim_type, claim_status) |>
      summarise(
        count = n(),
        total_amount = sum(claim_amount),
        .groups = "drop"
      )

    plot_ly(claims_summary,
            x = ~claim_type,
            y = ~count,
            color = ~claim_status,
            colors = c("Paid" = brand_success, "Denied" = brand_danger, "Pending" = brand_warning),
            type = "bar",
            text = ~count,
            textposition = "outside") |>
      layout(
        xaxis = list(title = ""),
        yaxis = list(title = "Number of Claims"),
        barmode = "group",
        legend = list(orientation = "h", y = -0.2)
      )
  })

  # Claims vs risk plot
  output$claims_risk_plot <- renderPlotly({
    claims_per_ind <- claims_history |>
      group_by(individual_id) |>
      summarise(num_claims = n(), .groups = "drop")

    claims_risk <- risk_profiles |>
      left_join(claims_per_ind, by = "individual_id") |>
      mutate(num_claims = replace_na(num_claims, 0)) |>
      filter(num_claims > 0)
    
    sample_size <- min(200, nrow(claims_risk))
    if (nrow(claims_risk) > sample_size) {
      claims_risk <- claims_risk |> slice_sample(n = sample_size)
    }

    plot_ly(claims_risk,
            x = ~overall_risk_score,
            y = ~num_claims,
            color = ~risk_category,
            colors = risk_colors,
            type = "scatter",
            mode = "markers",
            marker = list(size = 8, opacity = 0.6)) |>
      layout(
        xaxis = list(title = "Overall Risk Score"),
        yaxis = list(title = "Number of Claims"),
        legend = list(orientation = "h", y = -0.2)
      )
  })

  # Claims table
  output$claims_table <- DT::renderDataTable({
    claims_history |>
      arrange(desc(claim_date)) |>
      slice_head(n = 100) |>
      select(
        `Claim ID` = claim_id,
        Date = claim_date,
        Type = claim_type,
        Amount = claim_amount,
        Status = claim_status
      ) |>
      mutate(Amount = dollar(Amount))
  }, options = list(pageLength = 10, scrollX = TRUE))
}

# ==============================================================================
# RUN APP
# ==============================================================================

shinyApp(ui, server)
