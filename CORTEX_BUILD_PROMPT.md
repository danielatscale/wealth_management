# Live build with Snowflake Cortex Code

Branch `cortex_build` is the clean starting point: only `catalog.yml` (Horizon as the only context) and this
prompt, no model. Never build on it directly; cut a branch per run so the template stays clean.

## Run of show

1. **Before the build** (in a terminal, in `~/workspace/atscale/wealth_management`):
   ```
   git fetch origin && git switch cortex_build && git pull
   git switch -c cortex-<yyyymmdd-hhmm>        # e.g. cortex-20261113-1000
   cortex                                      # connection: demo; check /mcp shows atscale-demo-poc connected
   ```
2. **Start the build:** paste the **Demo prompt** below into Cortex. A build takes several minutes. If a rehearsal shows
   Cortex needs more guidance, use the **Full prompt** (or add the lines it needed to the demo prompt).
3. **While it builds:** demo the existing model (`wealth_portfolio_nlq_snowflake`) and the Snowflake Intelligence
   agent `Wealth Portfolio (AtScale)`.
4. **Back to Cortex:** show the files it wrote, its `sml-cli validate .` run and its commit and push.
5. **Publish** (with `.env` holding `ATSCALE_API_URL=https://demo.poc.atscale-se-demo.com/api` and a demo.poc token):
   ```
   set -a && . ./.env && set +a
   sml-cli atscale-deploy . --catalog-name=wealth_portfolio_cortex --catalog-label="Wealth Portfolio (Cortex)"
   ```
   Each run deploys over the same catalog `wealth_portfolio_cortex`, so the existing model is never touched.
6. **Test:** ask Cortex the questions in the prompt against the new catalog through the `atscale-demo-poc` tools
   (`list_models`, `run_query`), and compare with the existing model's answers.
7. **After the demo:** delete the run branch if you don't want to keep it
   (`git push origin --delete cortex-<yyyymmdd-hhmm>`).

## Demo prompt (short, reads well on screen)

The detail lives in `catalog.yml`, which Cortex reads; the prompt stays a business request, and nothing in it
tells Cortex how to model, so what it gets right comes from Horizon.

```
Build an AtScale semantic model for our wealth management data in Snowflake,
SE_DEMO_LIBRARY.WEALTH_PORTFOLIO_NLQ.

Use only the business context already in Snowflake Horizon: the table and column
comments, the keys, and the glossary in SE_DEMO_LIBRARY.METADATA. catalog.yml in
this folder says where everything is and which AtScale connection to use.

Use the AtScale MCP tools to design and write the model files here, and validate
them with sml-cli until they're clean.

The model needs to answer questions like:
- What was AUM by advisor at the end of Q2 2026, and how did it change vs Q1?
- What share of client assets sat in cash at each of the last 13 month ends?
- Which households have the largest AUM, and who is their advisor?
- What are realized vs unrealized gains year to date?
- Which accounts are most underweight in fixed income vs target?

When it validates, commit and push this branch. Don't deploy. Then give me a short
summary of what you built and which Horizon definitions you used.
```

Lines to add if a rehearsal shows Cortex needs them: "Call create_sml_model with confirmed: true, return_only: true
and write the YAML it returns yourself." and "Don't ask me questions; make reasonable choices and say what you chose."

## Full prompt (rehearsal / fallback)

---

You're on a fresh branch of the SML repo in the current folder. Read `catalog.yml` and follow its
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

Validate with `sml-cli validate .` until it reports no errors. Commit to the current branch and push it
(`git push -u origin HEAD`). Do not deploy, and do not switch or create branches.

This is an unattended run: don't ask questions; make the reasonable choice and say what you chose. When done,
give a short report: what you built (datasets, dimensions, metrics, calculations, the model name), how each of the
six questions maps to the model, and anything you could not resolve from Horizon.
