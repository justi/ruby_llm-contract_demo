# `ruby_llm-contract` LLM-judge demo

Runnable companion to the article *Schema valid != prawda. Druga warstwa walidacji LLM w Ruby* — shows why schema validation is not enough for content quality in LLM apps, and how an LLM-as-judge built as a [`ruby_llm-contract`](https://github.com/justi/ruby_llm-contract) Step closes the gap.

## Requirements

- Ruby 3.2+
- OpenAI API key (`gpt-4.1-mini`)
- ~$0.30 budget for the full lifecycle

## Quick start

```bash
bundle install
cp .env.example .env
$EDITOR .env          # paste OPENAI_API_KEY
LIVE=1 DEMO_LANG=pl bundle exec ruby scripts/01_eval_v1.rb
```

All scripts make live OpenAI calls. `LIVE=1` is required to confirm. `DEMO_LANG=pl` matches the article; `DEMO_LANG=en` (default) runs the English chatbot.

## Lifecycle

| Script | What it shows |
|---|---|
| `01_eval_v1.rb` | v1 strict prompt + refined judge → 5/5 PASS (faithful, robotic) |
| `02_eval_v2.rb` | v2 "be warm" PR + raw judge → 0/5 (drift visible) |
| `03_investigate.rb` | Per-claim breakdown: drift vs over-eager judge |
| `04_refined_judge.rb` | v2 + refined judge → 2/5 (signal vs noise) |
| `05_iterate.rb` | v3 prompt + refined judge → 5/5 PASS |
| `06_adversarial_v1.rb` | v1 vs 4 adversarial archetypes → 4/4 PASS |
| `07_adversarial_v2.rb` | v2 vs adversarial — validation_failed everywhere |
| `08_adversarial_v3.rb` | v3 vs adversarial — 3/4, 1 meta-rule leak |
| `09_iterate_v4.rb` | v4 (meta-rule ban) → 4/4 adversarial + 5/5 regression |
| `10_extended_policy.rb` | Alternative: extend source instead of iterating prompt |

Scripts are independent — run any one in isolation.

## License

MIT.
