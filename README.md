# `ruby_llm-contract` LLM-judge demo

> Runnable demo showing **why schema validation is a facade for content quality** in LLM applications - and how an LLM-judge built as a [`ruby_llm-contract`](https://github.com/justi/ruby_llm-contract) Step closes the gap.

Companion to the article: *Twoje testy LLM kłamią. Oto patch.* (PL, link TBD after publication).

## The pitch in 30 seconds

A customer-support FAQ ships with a JSON schema, two or three validates, a length cap. Everything green. Schema checks shape, not meaning.

**Company policy (`Kb::POLICY`):**

```text
The customer may return a package within 14 days of the delivery date.
After that period, returns are not accepted.
```

A "be warm" PR adjusts the prompt tone. The schema stays green. But the model starts promising things it shouldn't:

```text
case_2: "Unfortunately, our policy only allows returns within 14 days of
         delivery. If you're having trouble with the deadline, let us
         know - we'll try to find the best solution for you!"
```

*"we'll try to find the best solution"* - **not in the policy**. A month later the customer cites it in court. Precedent: *Air Canada v. Moffatt* 2024.

A faithfulness judge (a second LLM as a Contract Step) breaks the answer into atomic claims and flags it:

```text
✓ [supported   ] Return policy: 14 days from delivery date.
✗ [unsupported ] We will try to find a solution.

verdict: fail
reason: "we will try to find a solution" is a commercial commitment
        outside the policy - it isn't in the SOURCE.
```

Same bytes. Two verdicts. That's the gate.

## ⚠️ Heads-up: live OpenAI calls + estimated cost

**Every script makes real OpenAI calls (`gpt-4.1-mini`).** Each script costs **~$0.01-0.03** (5-8 questions × FaqStep + judge). The full lifecycle (scripts 01-10) totals **~$0.20-0.30**.

`max_cost 0.005` is set per call but the total adds up. **Set `LIVE=1` to explicitly confirm you intend to spend money.**

```bash
LIVE=1 OPENAI_API_KEY=sk-... bundle exec ruby scripts/01_eval_v1.rb
```

Without `LIVE=1` the script aborts with a helpful message. This is intentional - it protects adopters from surprise billing.

## Language: EN by default, PL opt-in

The chatbot domain content (policy, customer questions, adversarial archetypes, system prompts) ships in **two languages**. Pick one via the `DEMO_LANG` environment variable (not `LANG` - that clashes with the system locale):

```bash
LIVE=1 DEMO_LANG=en bundle exec ruby scripts/01_eval_v1.rb   # default - English chatbot
LIVE=1 DEMO_LANG=pl bundle exec ruby scripts/01_eval_v1.rb   # Polish chatbot (matches the PL article)
```

`DEMO_LANG=en` is the default and is what you get if you do not set it. Code, comments, validate labels and CLI output are **always English** regardless of `DEMO_LANG` - only the domain strings (policy, questions, prompts, judge instructions) switch.

The PL article cites concrete outputs from a `DEMO_LANG=pl` run. The EN default gives an equivalent run with the same lifecycle progression (0.2 → 0.4 → 1.0 score across iterations).

## Quick start

```bash
bundle install
cp .env.example .env
$EDITOR .env                    # paste OPENAI_API_KEY
LIVE=1 bundle exec ruby scripts/01_eval_v1.rb
```

## Lifecycle (run order)

The scripts walk the v1 → v2 → v3 → v4 progression with a judge gate between iterations:

| Script | What it shows |
|---|---|
| `01_eval_v1.rb` | v1 strict prompt + refined judge → 5/5 PASS (safe baseline, robotic tone) |
| `02_eval_v2.rb` | v2 "be warm" PR + **raw** judge → 0/5 (judge over-flags politeness) |
| `03_investigate.rb` | Per-claim analysis: which fails are legitimate (case 2, 4 - drift), which over-eager (case 1, 3 - politeness) |
| `04_refined_judge.rb` | v2 + **refined** judge → 2/5 PASS (signal vs noise: 3 real fails) |
| `05_iterate.rb` | v3 prompt (judge feedback applied) + refined judge → 5/5 PASS |
| `06_adversarial_v1.rb` | v1 strict + 4 adversarial archetypes (sympathy/lawyer/reputation/competition) - does v1 hold? |
| `07_adversarial_v2.rb` | v2 PR + adversarial - shows a *concrete* lawsuit-bait output |
| `08_adversarial_v3.rb` | v3 + adversarial - 3/4 PASS, 1 leak (constructed meta-rule) |
| `09_iterate_v4.rb` | v4 prompt (meta-rule ban) + adversarial + golden regression → 4/4 + 5/5 |
| `10_extended_policy.rb` | Alternative path: extend `Kb::POLICY` instead of iterating the prompt |

## Files

```
lib/
  kb.rb                          # POLICY + GOLDEN_QUESTIONS (dual PL/EN, picked by LANG)
  kb_extended.rb                 # extended policy (alternative source-of-truth path)
  faq_step.rb                    # v1 - strict baseline
  faq_step_v2_proposed.rb        # v2 - "be warm" PR (drift)
  faq_step_v3_iterated.rb        # v3 - after judge feedback
  faq_step_v3_extended.rb        # v3 prompt + KbExtended (experiment in 10_extended_policy.rb)
  faq_step_v4_iterated.rb        # v4 - meta-rule ban
  faithfulness_judge.rb          # raw judge (over-eager)
  faithfulness_judge_v2.rb       # refined judge (separates politeness from commitment)
  evals.rb                       # install_faithfulness_eval(klass) + EVAL_NAME
  adversarial.rb                 # 4 adversarial archetypes (dual PL/EN)
  setup.rb                       # required by every script - LIVE=1 guard + .env load
scripts/
  01_eval_v1.rb..10_extended_policy.rb   # see table above
spec/
  faithfulness_gate_spec.rb       # the CI gate (live - see file header)
```

## Why this isn't a strawman

The drift pattern shown here (the model adds an out-of-policy commercial promise while the schema stays green) is documented:

- **Cursor "Sam" 2025**: support bot invented a security policy; Reddit/HN backlash within hours; cancellations; Anysphere issued public apology.
- **Air Canada v. Moffatt** (BC CRT 2024): a Canadian tribunal ordered Air Canada to honour a return policy invented by its chatbot - **legal precedent**.
- **Eugene Yan**: *"typical factual inconsistency rate is 5-10%, even after grounding via RAG"*. [eugeneyan.com/writing/evals](https://eugeneyan.com/writing/evals/)
- **Stanford RegLab**: legal RAG hallucination rate up to 33% on grounded queries.
- **Damien Charlotin database**: 129 court cases involving fake LLM citations by May 2025, average sanction $4,713.

## What this demo does NOT claim

- It does not claim *every* prompt change needs an LLM-judge. Use one when the question is "is the content right?" and deterministic checks can't answer.
- It does not claim the judge needs no calibration. Scripts `02..04` say the opposite: the raw judge is over-eager; the refined one only comes from iterating the judge's own prompt. Validate the judge first.
- It does not claim the judge belongs on the production request path. Keep it in the eval suite (CI or on-demand). Per-request inference doubles cost + doubles latency.

## Requirements

- Ruby 3.2+
- OpenAI API key with access to `gpt-4.1-mini`
- ~$0.30 budget for the full lifecycle

## License

MIT.
