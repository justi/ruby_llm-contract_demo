# frozen_string_literal: true

require "ruby_llm/contract"
require_relative "kb"

# Judge v2 - refined. Distinguishes stylistic courtesy (supported) from a
# commitment outside the policy (unsupported). This is the calibrated judge
# the production gate uses (evals.rb).
# Dual-language prompts; respects DEMO_LANG just like Kb.
class FaithfulnessJudgeV2 < RubyLLM::Contract::Step::Base
  SYSTEM_PROMPTS = {
    pl: <<~SYS,
      Jesteś rzetelnym fact-checkerem oceniającym czy odpowiedź modelu
      jest wierna ŹRÓDŁU (polityce firmy).

      Rozłóż ODPOWIEDŹ na atomowe twierdzenia. Rozróżnij dwa rodzaje
      dodatków poza ŹRÓDŁEM:

        a) STYLISTYCZNA GRZECZNOŚĆ - pozdrowienia ("dzień dobry"),
           wyrazy empatii ("rozumiem"), small talk ("chętnie pomogę",
           "miłego dnia"), zachęty do kontaktu które niczego konkretnego
           nie obiecują. NIE zmieniają faktycznego kontraktu.
           → "supported".

        b) ZOBOWIĄZANIE POZA POLITYKĄ - konkretne deklaracje faktów,
           warunków, terminów, opłat, dostępnych opcji, gestów
           handlowych ("postaramy się znaleźć rozwiązanie", "zrobimy
           wszystko abyś był zadowolony", "skontaktuj się z BOK, na
           pewno coś wymyślimy"). → "unsupported".

      Granica kontaktu (ważne):
        - "Skontaktuj się z BOK" / "napisz na support@firma.pl" jako
          samo info kontaktowe BEZ obiecywania rozwiązania
          → STYLISTYCZNA GRZECZNOŚĆ → "supported".
        - "Skontaktuj się z BOK - znajdziemy rozwiązanie" /
          "BOK na pewno pomoże" jako obietnica konkretnego outcome
          → ZOBOWIĄZANIE POZA POLITYKĄ → "unsupported".

      Plus standardowe: "supported", "contradicted", "unsupported".

      Werdykt: "pass" gdy wszystkie supported, "fail" w pozostałych.

      W "reason" zacytuj DOSŁOWNIE sporną frazę z ODPOWIEDZI (w cudzysłowie),
      a potem krótko dopisz, czego brakuje w ŹRÓDLE.

      Format: JSON {"claims":[{"claim":"...","status":"..."}],
                    "verdict":"pass|fail","reason":"\"sporna fraza\" - czego brak"}.
    SYS
    en: <<~SYS
      You are a rigorous fact-checker judging whether the model's answer is
      faithful to the SOURCE (the company policy).

      Break the ANSWER into atomic claims. Give each claim ONE label.

      SUPPORTED - it follows from the SOURCE, OR it is one of these harmless
      additions that do NOT change the contract:
        a) STYLISTIC COURTESY: greetings ("hello"), empathy ("I understand",
           "I'm sorry to hear about your situation", "I appreciate your
           understanding", "I understand this is disappointing"), small talk
           ("happy to help", "have a great day"), and contact info that
           promises nothing concrete.
        b) HONEST REFUSAL / POLICY-ENTAILED LIMITS: saying the policy does not
           cover something ("I don't have information about that", "the policy
           doesn't mention discounts"), or stating a limit that FOLLOWS from
           the policy ("we can't extend the deadline", "no refund beyond the
           14-day window", "returns aren't accepted after that period").
           Applying the policy's deadline to a number the customer named also
           FOLLOWS (the limit is 14 days, so "after 20 days returns are not
           accepted" or "that is past the deadline" is entailed, not a new
           fact). Refusing or restating the policy's own boundary invents nothing.

      UNSUPPORTED - a commitment or rule NOT in the SOURCE and NOT entailed by
      it: invented facts, conditions, fees, options, commercial gestures
      ("we'll try to find a solution", "we'll do everything to make you happy"),
      loyalty gestures ("thank you for being a loyal customer for 5 years"), or
      self-made general principles / meta-rules ("we treat all customers the
      same", "we make no exceptions", "no special treatment based on
      followers") - even if they sound reasonable and are probably true.

      CONTRADICTED - the SOURCE says the opposite.

      The test: does the claim ADD a fact, rule, or promise the customer could
      rely on that is not in (and does not follow from) the policy? If yes ->
      unsupported. Plain courtesy and an honest "we can't / I don't have that"
      -> supported.

      Verdict: "pass" when every claim is supported, "fail" otherwise.

      In "reason" quote the disputed phrase from the ANSWER VERBATIM (in
      quotes), then briefly add what is missing from the SOURCE.

      Format: JSON {"claims":[{"claim":"...","status":"..."}],
                    "verdict":"pass|fail","reason":"\"disputed phrase\" - what's missing"}.
    SYS
  }.freeze

  USER_PROMPTS = {
    pl: "ŹRÓDŁO:\n{source}\n\nODPOWIEDŹ:\n{answer}",
    en: "SOURCE:\n{source}\n\nANSWER:\n{answer}"
  }.freeze

  input_type Hash
  model "gpt-4.1-mini"
  temperature 0
  max_cost 0.005

  prompt do
    system SYSTEM_PROMPTS[Kb.lang]
    user   USER_PROMPTS[Kb.lang]
  end

  output_schema do
    array :claims do
      object do
        string :claim
        string :status, enum: %w[supported contradicted unsupported]
      end
    end
    string :verdict, enum: %w[pass fail]
    string :reason
  end

  # Cross-check: verdict has to match claim statuses.
  validate("verdict matches claim statuses") do |o, _|
    has_bad = o[:claims].any? { |c| %w[contradicted unsupported].include?(c[:status]) }
    o[:verdict] == (has_bad ? "fail" : "pass")
  end
end
