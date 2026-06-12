# `ruby_llm-contract` LLM-judge demo

> Runnable demo pokazujący **dlaczego schema validation to fasada dla content quality** w aplikacjach LLM - i jak LLM-judge zbudowany jako [`ruby_llm-contract`](https://github.com/justi/ruby_llm-contract) Step zamyka tę lukę.

Companion do artykułu: *Twoje testy LLM kłamią. Oto patch.* (link TODO po publikacji).

## Pitch w 30 sekund

Customer support FAQ ma JSON schema, 2-3 walidatory, length cap. Wszystko zielone. Schema sprawdza shape, nie meaning.

**Polityka firmy:**

```ruby
Kb::POLICY = "Klient może zwrócić paczkę w ciągu 14 dni od daty dostawy. " \
             "Po upływie tego terminu zwroty nie są przyjmowane."
```

PR "be warm" zmienia ton prompt'a. Schema dalej zielona. Ale model zaczyna obiecywać:

```text
case_2: "Niestety, nasza polityka pozwala na zwrot tylko w ciągu 14 dni
         od daty dostawy. Jeśli masz trudności z terminem, daj nam znać
         - postaramy się znaleźć dla Ciebie jak najlepsze rozwiązanie!"
```

*"postaramy się znaleźć rozwiązanie"* - **nie ma w polityce**. Klient za miesiąc cytuje to w sądzie. Precedens: *Air Canada v. Moffatt* 2024.

Faithfulness judge (drugi LLM jako Contract Step) rozkłada odpowiedź na atomic claims i flaguje:

```text
✓ [supported   ] Polityka zwrotów: 14 dni od daty dostawy.
✗ [unsupported ] Postaramy się znaleźć rozwiązanie.

verdict: fail
reason: "postaramy się znaleźć rozwiązanie" to obietnica handlowa
        poza polityką - nie ma w SOURCE.
```

Te same bajty. Dwa werdykty. To jest bramka.

## ⚠️ Heads-up: live OpenAI calls + szacowany koszt

**Wszystkie scripty wywołują real OpenAI (`gpt-4.1-mini`).** Każdy script kosztuje **~$0.01-0.03** (5-8 pytań × FaqStep + judge). Pełen lifecycle (scripts 01-10) to **~$0.20-0.30**.

`max_cost 0.005` per call jest set, ale total się sumuje. **Set `LIVE=1` żeby explicit confirm że chcesz wydać $.**

```bash
LIVE=1 OPENAI_API_KEY=sk-... bundle exec ruby scripts/01_eval_v1.rb
```

Bez `LIVE=1` script aborts z helpful message. To celowe - chronimy adopter'a przed niespodziewanym billingiem.

## Quick start

```bash
bundle install
cp .env.example .env
$EDITOR .env                    # wpisz OPENAI_API_KEY
LIVE=1 bundle exec ruby scripts/01_eval_v1.rb
```

## Lifecycle (run order)

Scripty pokazują progresję v1 → v2 → v3 → v4 z bramką judge między iteracjami:

| Script | Co pokazuje |
|---|---|
| `01_eval_v1.rb` | v1 strict prompt + dopracowany judge → 5/5 PASS (baseline safe but robotic) |
| `02_eval_v2.rb` | v2 PR "be warm" + **surowy** judge → 0/5 (judge over-flag'uje grzeczność) |
| `03_investigate.rb` | Per-claim analiza: które fail'e są legit (case 2, 4 - dryf), które przesadne (case 1, 3 - grzeczność) |
| `04_refined_judge.rb` | v2 + **dopracowany** judge → 2/5 PASS (sygnał vs szum: 3 realne fail) |
| `05_iterate.rb` | v3 prompt (judge feedback applied) + dopracowany judge → 5/5 PASS |
| `06_adversarial_v1.rb` | v1 strict + 4 archetypy adversarial (sympathy/lawyer/reputation/competition) - czy v1 wytrzymuje? |
| `07_adversarial_v2.rb` | v2 PR + adversarial - pokazuje *konkretny* pozew-bait output |
| `08_adversarial_v3.rb` | v3 + adversarial - 3/4 PASS, 1 leak (meta-rule konstrukcja) |
| `09_iterate_v4.rb` | v4 prompt (zakaz meta-reguł) + adversarial + golden regression → 4/4 + 5/5 |
| `10_extended_policy.rb` | Alternatywne podejście: rozszerzyć `Kb::POLICY` zamiast iterować prompt |

## Files

```
lib/
  kb.rb                          # Kb::POLICY (1-liner) + Kb::GOLDEN_QUESTIONS (5 pytań ref)
  kb_extended.rb                 # rozszerzona polityka (alternatywne podejście)
  faq_step.rb                    # v1 - strict baseline
  faq_step_v2_proposed.rb        # v2 - "be warm" PR (drift)
  faq_step_v3_iterated.rb        # v3 - po judge feedback
  faq_step_v3_extended.rb        # v3 prompt + KbExtended (eksperyment z 10_extended_policy.rb)
  faq_step_v4_iterated.rb        # v4 - zakaz meta-reguł
  faithfulness_judge.rb          # surowy judge (nadgorliwy)
  faithfulness_judge_v2.rb       # dopracowany judge (rozróżnia grzeczność vs obietnica)
  evals.rb                       # install_faithfulness_eval(klass) + EVAL_NAME
  adversarial.rb                 # 4 archetypy adversarial inputs
  setup.rb                       # require "setup" w każdym script - LIVE=1 guard + .env load
scripts/
  01_eval_v1.rb..10_extended_policy.rb   # patrz tabela wyżej
spec/
  faithfulness_gate_spec.rb       # bramka CI (live - patrz ostrzeżenie w pliku)
```

## Why this isn't a strawman

Drift category pokazana w demo (model dodaje obietnicę handlową poza polityką, schema zielona) jest udokumentowana:

- **Cursor "Sam" 2025**: support bot wymyślił security policy, Reddit/HN backlash w godzinach, cancellations, Anysphere wystosował przeprosiny.
- **Air Canada v. Moffatt** (BC CRT 2024): sąd nakazał honorować politykę zwrotów, którą wymyślił chatbot - **precedens prawny**.
- **Eugene Yan**: *"typical factual inconsistency rate is 5-10%, even after grounding via RAG"*. [eugeneyan.com/writing/evals](https://eugeneyan.com/writing/evals/)
- **Stanford RegLab**: legal RAG hallucination rate do 33% na grounded queries.
- **Damien Charlotin database**: 129 spraw sądowych z fake LLM citations do maja 2025, średnia kara $4,713.

## Czego ten demo NIE twierdzi

- Nie twierdzi że *każda* zmiana promptu wymaga LLM-judge. Używaj judge gdy pytanie to "czy treść jest poprawna?" i deterministic checks nie odpowiedzą.
- Nie twierdzi że judge nie wymaga walidacji. Punkt `scripts/02..04` jest dokładnie odwrotny: surowy judge nadgorliwy, dopracowany dopiero po iteracji prompt'a judge'a. Validate the judge first.
- Nie twierdzi że judge należy na ścieżce produkcyjnej. Trzymaj go w eval suite (CI lub on-demand). Inference per request to 2x koszt + 2x latencja.

## Wymagania

- Ruby 3.2+
- OpenAI API key z dostępem do `gpt-4.1-mini`
- Budget ~$0.30 na pełen przebieg lifecycle

## License

MIT.
