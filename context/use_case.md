# wealth_portfolio_nlq — Client Portfolio Performance & Allocation

A conversational-BI / semantic-layer demo dataset for **Merrill Lynch wealth
management**, investor/portfolio side. Advisors and clients ask natural-language
questions about portfolio performance, allocation drift, exposure, gains, and AUM; the
semantic layer answers them off this star schema. Synthetic, deterministic (seed 42),
single currency (USD), 36 monthly month-end snapshots ending **2026-06-30**.

## Scenario

A wirehouse advisory book: ~1,500 households (Mass Affluent / HNW / UHNW) across ~3,300
accounts (Brokerage, IRAs, 401(k) Rollover, Trust), each mapped to a target risk model
(Conservative / Moderate / Growth / Aggressive). Positions are held in ~360 securities
spanning Equity (with GICS sectors), Fixed Income, Cash, and Alternatives. The window is
a multi-year bull market (S&P 500 ~24% over 3 years, ~9% YTD 2026; Aggregate Bond ~4%
over 3 years), which is what makes the performance and drift questions interesting.

## Brief NLQs (the questions the demo must answer)

1. **How did my portfolio perform vs the S&P 500 year-to-date?**
2. **Which accounts have drifted most from their target allocation?**
3. **What's my exposure to equities / to a sector like technology?**
4. **What are my realized vs unrealized gains year-to-date?**
5. **Which households have the largest AUM (and who's the advisor)?**
6. What was AUM by advisor at the end of Q3, and how did it compare to Q2?
7. What share of total client assets sat in cash at each of the last 13 month ends?
8. This uses Asset Class Market Value for cash over total Market Value, or Actual Allocation Pct by asset class.
9. What’s the total AUM for households whose accounts span more than one advisor? 
10. How has total market value changed vs the same month last year, by advisor? (Market Value Prior Year)
11. Which securities drove the most realized gains year to date, and which booked realized losses?
12. How does unrealized gain today compare with a year ago?
13. Which accounts are most underweight in fixed income vs target?
14. Which accounts beat the benchmark’s monthly return most often this year? 

## Engineered narratives (baked into the data, seed 42)

- **Diversification vs the index (NLQ1).** In the up market, more-equity portfolios beat
  the S&P 500 and diversified/conservative ones lag: Conservative accounts average ~4%
  YTD, Aggressive ~11% vs the **9.3% S&P 500 YTD**; ~430 accounts beat the index, almost
  all Growth/Aggressive. The S&P is engineered as a cap-weighted, tech-tilted index so
  only genuinely equity- or tech-heavy books clear it.
- **Allocation drift cohort (NLQ2).** ~35% of accounts are "never rebalanced" and started
  equity-overweight; by the current month they carry **+10 to +21 points** of equity
  overweight vs their model target, while disciplined accounts sit ~0. Clear bimodal
  "which accounts drifted most" answer.
- **Technology concentration (NLQ3).** Technology is the single largest equity-sector
  exposure book-wide (~$8.2B), and a tech-tilt cohort runs up to ~85% of the portfolio in
  Technology — the "what's my tech exposure" drill.
- **Gains, realized vs unrealized (NLQ4).** ~$3.3B of **unrealized** gains sit in current
  positions; **realized YTD 2026** is a small ~$8M (winner trims), while the **Dec-2025**
  tax-loss-harvest batch is a net realized **loss** (~-$11M) — the realized/unrealized and
  short/long-term story.
- **Segment AUM tiers (NLQ5).** UHNW ~$104M avg household AUM, HNW ~$12M, Mass Affluent
  ~$1M; ~$19.8B total book. Each household rolls up to one advisor.

## Grain

| Table | Grain |
|---|---|
| `fact_position_snapshot` | one row per account × security × month-end (the core fact) |
| `fact_account_performance` | one row per account × month-end (value, net flow, monthly return) |
| `fact_benchmark_return` | one row per benchmark × month-end (S&P 500, US Agg Bond, 60/40) |
| `fact_realized_gain` | one row per realized sell lot (Dec-2025 TLH + 2026 YTD trims) |

Conformed dimensions: `dim_date` (monthly), `dim_advisor`, `dim_household`,
`dim_account`, `dim_security`, `dim_model_target` (model × asset_class target %).

## Aggregate shape (seed 42, current month 2026-06)

- Households 1,500 (Mass Affluent 937 / HNW 432 / UHNW 131); accounts 3,315; securities 360.
- Total AUM ~$19.8B; unrealized gains ~$3.3B; positions 2,134,728 rows.
- S&P 500: +9.3% YTD, +24.1% over the 36-month window; US Aggregate Bond +4.3%.

## Known limitations

- **Net flows are not modeled** (`net_flow = 0`); monthly return is pure
  investment performance. Net-new-asset / flow questions are out of scope (a different
  use case — see `use_cases_excluded`).
- **Realized-gain events are standalone**, not reconciled to position quantity changes
  (a demo simplification); unrealized gains do reconcile to positions.
- Single currency (USD), no FX; no tax-lot-level cost layering beyond short/long term.
- Disciplined accounts are anchored to target at a recent month, so their pre-anchor
  monthly allocation is approximate; current-month allocation (what the NLQs query) is
  exact.
- Monthly snapshots, not a daily ledger; intramonth trading is not represented.
- Benchmarks are synthetic index paths, not real S&P 500 / Bloomberg Agg values.
