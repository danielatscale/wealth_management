# Agent rules for this repo

- When asked to publish or deploy the AtScale model, only publish it and report that it is published.
  Do not then run test queries or the business questions (no `list_models`, `run_query` or other query tools)
  unless the user explicitly asks for queries in a later message.
- Follow `catalog.yml` `ai_context` for where the business context lives and which connection to use.
