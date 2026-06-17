-- 02_ddl.sql — wealth_portfolio_nlq schema (Databricks SQL / Delta, Unity Catalog)
-- 6 dimensions + 4 facts. Single currency (USD). Monthly month-end snapshots.
--
-- Types: BIGINT ids/counts, DECIMAL(18,2) money, DOUBLE ratios/returns/pct,
-- STRING text, DATE dates, BOOLEAN flags. PRIMARY KEY declared (informational /
-- NOT ENFORCED on UC; PK cols are NOT NULL). FOREIGN KEYs kept as comments — the
-- AtScale semantic model owns the joins. Facts use liquid clustering (DBR 13.3+).
-- ${CATALOG} / ${SCHEMA} are substituted by load.sh.

-- ============================================================
-- Dimensions
-- ============================================================
CREATE OR REPLACE TABLE `${CATALOG}`.`${SCHEMA}`.dim_date (
  date_id        DATE   NOT NULL,
  year_num       BIGINT,
  month_num      BIGINT,
  month_name     STRING,
  year_month     STRING,
  quarter_num    BIGINT,
  quarter_name   STRING,
  is_quarter_end BOOLEAN,
  is_year_end    BOOLEAN,
  CONSTRAINT dim_date_pk PRIMARY KEY (date_id)
);

CREATE OR REPLACE TABLE `${CATALOG}`.`${SCHEMA}`.dim_advisor (
  advisor_id    BIGINT NOT NULL,
  advisor_name  STRING,
  office_region STRING,
  tenure_years  BIGINT,
  is_senior     BOOLEAN,
  CONSTRAINT dim_advisor_pk PRIMARY KEY (advisor_id)
);

CREATE OR REPLACE TABLE `${CATALOG}`.`${SCHEMA}`.dim_household (
  household_id     BIGINT NOT NULL,
  household_name   STRING,
  segment          STRING,          -- Mass Affluent | HNW | UHNW
  region           STRING,
  advisor_id       BIGINT,
  acquisition_date DATE,
  CONSTRAINT dim_household_pk PRIMARY KEY (household_id)
  -- FK (intended): advisor_id -> dim_advisor(advisor_id)
);

CREATE OR REPLACE TABLE `${CATALOG}`.`${SCHEMA}`.dim_account (
  account_id   BIGINT NOT NULL,
  household_id BIGINT,
  account_type STRING,              -- Brokerage | Traditional IRA | Roth IRA | 401(k) Rollover | Trust
  registration STRING,
  risk_model   STRING,              -- Conservative | Moderate | Growth | Aggressive
  open_date    DATE,
  CONSTRAINT dim_account_pk PRIMARY KEY (account_id)
  -- FK (intended): household_id -> dim_household(household_id)
);

CREATE OR REPLACE TABLE `${CATALOG}`.`${SCHEMA}`.dim_security (
  security_id   BIGINT NOT NULL,
  ticker        STRING,
  security_name STRING,
  asset_class   STRING,             -- Equity | Fixed Income | Cash | Alternative
  sector        STRING,             -- GICS sector for equities; '-' otherwise
  region        STRING,             -- US | International
  expense_ratio DOUBLE,
  CONSTRAINT dim_security_pk PRIMARY KEY (security_id)
);

CREATE OR REPLACE TABLE `${CATALOG}`.`${SCHEMA}`.dim_model_target (
  model       STRING NOT NULL,      -- risk model
  asset_class STRING NOT NULL,
  target_pct  DOUBLE,               -- target allocation % for the model
  CONSTRAINT dim_model_target_pk PRIMARY KEY (model, asset_class)
);

-- ============================================================
-- Facts
-- ============================================================
CREATE OR REPLACE TABLE `${CATALOG}`.`${SCHEMA}`.fact_position_snapshot (
  position_id     BIGINT NOT NULL,
  snapshot_date   DATE,
  account_id      BIGINT,
  security_id     BIGINT,
  quantity        DECIMAL(18,2),
  price           DECIMAL(18,2),
  market_value    DECIMAL(18,2),
  cost_basis      DECIMAL(18,2),
  unrealized_gain DECIMAL(18,2),
  CONSTRAINT fact_position_snapshot_pk PRIMARY KEY (position_id)
  -- FK (intended): account_id -> dim_account, security_id -> dim_security,
  --                snapshot_date -> dim_date
)
CLUSTER BY (snapshot_date, account_id);

CREATE OR REPLACE TABLE `${CATALOG}`.`${SCHEMA}`.fact_account_performance (
  perf_id         BIGINT NOT NULL,
  snapshot_date   DATE,
  account_id      BIGINT,
  beginning_value DECIMAL(18,2),
  net_flow        DECIMAL(18,2),
  ending_value    DECIMAL(18,2),
  monthly_return  DOUBLE,           -- % for the month
  CONSTRAINT fact_account_performance_pk PRIMARY KEY (perf_id)
  -- FK (intended): account_id -> dim_account, snapshot_date -> dim_date
)
CLUSTER BY (snapshot_date, account_id);

CREATE OR REPLACE TABLE `${CATALOG}`.`${SCHEMA}`.fact_benchmark_return (
  benchmark_id   STRING NOT NULL,   -- BM_SPX | BM_AGG | BM_6040
  benchmark_name STRING,
  snapshot_date  DATE   NOT NULL,
  index_level    DECIMAL(18,2),
  monthly_return DOUBLE,            -- % for the month
  CONSTRAINT fact_benchmark_return_pk PRIMARY KEY (benchmark_id, snapshot_date)
);

CREATE OR REPLACE TABLE `${CATALOG}`.`${SCHEMA}`.fact_realized_gain (
  realized_id   BIGINT NOT NULL,
  account_id    BIGINT,
  security_id   BIGINT,
  sell_date     DATE,
  quantity      DECIMAL(18,2),
  proceeds      DECIMAL(18,2),
  cost_basis    DECIMAL(18,2),
  realized_gain DECIMAL(18,2),      -- negative = realized loss (e.g. Dec-2025 TLH)
  term          STRING,             -- Short | Long
  CONSTRAINT fact_realized_gain_pk PRIMARY KEY (realized_id)
  -- FK (intended): account_id -> dim_account, security_id -> dim_security
)
CLUSTER BY (sell_date);
