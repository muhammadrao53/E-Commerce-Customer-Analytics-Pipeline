# E-Commerce Customer Analytics: From Raw Data to ML-Driven Insights

An end-to-end data analytics project covering the full pipeline: SQL data cleaning → interactive Power BI dashboard → Python exploratory analysis → customer segmentation (K-Means) → predictive modeling (scikit-learn vs. TensorFlow).

Rather than treating each tool as a separate exercise, this project follows one dataset through a real analytics workflow — including two moments where the data itself changed the plan: a return-prediction model was abandoned after rigorous testing showed no learnable signal, and a different, evidence-backed target was found instead.

---

## Project Pipeline

| Stage | Tool | What it does |
|---|---|---|
| 1. Data Cleaning | PostgreSQL | Cleans and validates the raw dataset, resolves nulls, recalculates inconsistent totals, builds a customer-level summary table |
| 2. Dashboard | Power BI | Interactive dashboard — KPI cards, sales trends, category/region breakdowns, filterable by demographics |
| 3. EDA | Python (Pandas, Matplotlib, Seaborn) | Distributions, correlations, return-rate patterns, customer-level analysis |
| 4. Segmentation | Python (scikit-learn) | RFM feature engineering + K-Means clustering into 4 actionable customer segments |
| 5. Classification | Python (scikit-learn + TensorFlow) | Predictive modeling comparison — Logistic Regression, Random Forest, and a Keras neural network |

## Key Findings

- **86% of customers are repeat buyers**, but revenue is concentrated: the top segment (**Champions**, 4.8% of customers) drives **18.8% of total revenue**, while **Loyal Customers** (34.6% of customers) alone account for nearly half of all revenue (48.9%).
- **17.8% of customers are "At Risk / Lost"** — averaging 240 days since their last order — representing a concrete re-engagement target.
- A return-risk classification model was planned, but **rigorous testing (5-fold cross-validation + statistical significance tests) showed no feature in the dataset meaningfully predicts returns** (all p-values > 0.05, ROC-AUC ≈ 0.48-0.53 across models). Rather than force a misleading result, the target was changed to a different, evidence-backed prediction task.
- On the revised target, **Logistic Regression, Random Forest, and a neural network all performed within ~1 percentage point of each other** (ROC-AUC 0.982-0.990) — a legitimate finding that the added complexity of deep learning wasn't justified on this clean, low-dimensional relationship.

## Repository Structure

```
ecommerce-customer-analytics/
├── data/
│   ├── raw/                        # Original, unmodified source dataset
│   └── processed/                  # Cleaned & enriched outputs from the SQL script
├── sql/
│   └── 01_data_cleaning.sql        # PostgreSQL cleaning + transformation script
├── notebooks/
│   ├── 01_eda.ipynb
│   ├── 02_customer_segmentation.ipynb
│   ├── 03_classification_models.ipynb
│   └── figures/                    # Chart images used in each notebook
├── dashboard/
│   └── ecommerce_customer_analytics_dashboard.pbix
├── requirements.txt
└── README.md
```

## How to Reproduce

1. **Database setup:** run `sql/01_data_cleaning.sql` against a PostgreSQL instance loaded with `data/raw/ecommerce_sales_raw.csv`. Outputs two tables, matching the files already provided in `data/processed/`.
2. **Python environment:**
   ```
   pip install -r requirements.txt
   ```
3. **Notebooks:** run in order — `01_eda.ipynb` → `02_customer_segmentation.ipynb` → `03_classification_models.ipynb`. Each reads from `data/processed/`.
4. **Dashboard:** open `dashboard/ecommerce_customer_analytics_dashboard.pbix` in Power BI Desktop.

## Tech Stack

**Database:** PostgreSQL &nbsp;|&nbsp; **BI:** Power BI &nbsp;|&nbsp; **Python:** Pandas, NumPy, Matplotlib, Seaborn, scikit-learn, TensorFlow/Keras, SciPy

## Author

Muhammad Abbas Rao — BS Business Analytics, FAST National University, Karachi
