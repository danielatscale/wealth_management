# Build prompt for Snowflake Cortex Code

Start Cortex Code in this folder (branch `cortex_build` of `danielatscale/wealth_management`) with the Snowflake
connection `demo` and the MCP server `atscale-demo-poc` connected, then paste everything below the line.

---

You're on branch `cortex_build` of the SML repo in the current folder. Read `catalog.yml` and follow its
`ai_context`: Snowflake Horizon for `SE_DEMO_LIBRARY.WEALTH_PORTFOLIO_NLQ` is the only business context, and the
rows come through the AtScale connection `Snowflake Partner`.

Build an AtScale semantic model for this wealth-management data: a wirehouse advisory book with advisors,
households, accounts, securities, month-end position snapshots, monthly account performance, benchmark returns
and realized gains.

How to build:
- Use the AtScale MCP server `atscale-demo-poc` for everything AtScale. Start with `get_sml_skills` and follow
  the `create-model-workflow` skill and the `sml-create-*` sub-skills it names. Use `explore_datasource` on the
  connection `Snowflake Partner` (database `SE_DEMO_LIBRARY`, schema `WEALTH_PORTFOLIO_NLQ`) for tables, columns
  and samples.
- Read the Horizon metadata with SQL on your Snowflake connection, exactly as `catalog.yml` describes: column
  and table comments, primary and foreign keys, and the glossary in `SE_DEMO_LIBRARY.METADATA`.
- The MCP server runs remotely, so call `create_sml_model` with `confirmed: true, return_only: true` and write
  the YAML it returns into this folder yourself. Use the standard layout: `connections/`, `datasets/`,
  `dimensions/`, `metrics/`, `calculations/`, `models/`, with `catalog.yml` at the root.
- Do not read any existing AtScale model or catalog, on this or any other instance, and do not look at other
  branches of this repo. Build from Horizon and the warehouse only.

What the model must get right (from the Horizon comments and glossary):
- AUM / market value is a month-end balance: semi-additive, last month end in any period, never summed across
  months.
- Allocation drift is actual minus target per account and asset class; never totalled across accounts.
- Realized gains are additive; their sell dates are not always month ends, so join the monthly date on the month
  end of the sell date.
- Publish the glossary's formula terms as calculations over component measures (for example cash share,
  quarter-over-quarter AUM change, realized gains year to date).

The model must answer these questions:
1. What was AUM by advisor at the end of Q2 2026, and how did it change vs Q1 2026?
2. What share of total client assets sat in cash at each of the last 13 month ends?
3. Which 10 households have the largest AUM today, and who is their advisor?
4. What are realized vs unrealized gains year to date?
5. What is our exposure to equities by sector today?
6. Which accounts are most underweight in fixed income vs target?

Validate with `sml-cli validate .` until it reports no errors. Commit to this branch and push it
(`git push -u origin cortex_build`). Do not deploy.

This is an unattended run: don't ask questions; make the reasonable choice and say what you chose. When done,
give a short report: what you built (datasets, dimensions, metrics, calculations, the model name), how each of the
six questions maps to the model, and anything you could not resolve from Horizon.
