# frozen_string_literal: true

require "ruby_llm/contract"
require_relative "kb"

# Judge v2 — refined. Distinguishes stylistic courtesy (supported) from a
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

        a) STYLISTYCZNA GRZECZNOŚĆ — pozdrowienia ("dzień dobry"),
           wyrazy empatii ("rozumiem"), small talk ("chętnie pomogę",
           "miłego dnia"), zachęty do kontaktu które niczego konkretnego
           nie obiecują. NIE zmieniają faktycznego kontraktu.
           → "supported".

        b) ZOBOWIĄZANIE POZA POLITYKĄ — konkretne deklaracje faktów,
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

      Break the ANSWER into atomic claims. Distinguish two kinds of additions
      outside the SOURCE:

        a) STYLISTIC COURTESY — greetings ("hi"), expressions of empathy
           ("I understand"), small talk ("happy to help", "have a great
           day"), contact encouragements that promise nothing concrete.
           These do NOT change the actual contract.
           → "supported".

        b) COMMITMENT OUTSIDE POLICY — concrete declarations of facts,
           conditions, deadlines, fees, available options, commercial
           gestures ("we'll try to find a solution", "we'll do everything
           to make you happy", "contact support — we'll figure something
           out"). → "unsupported".

      Contact boundary (important):
        - "Contact support" / "email support@company.com" as plain contact
          info WITHOUT promising a resolution
          → STYLISTIC COURTESY → "supported".
        - "Contact support — we'll find a solution" / "support will
          definitely help" as a promise of a concrete outcome
          → COMMITMENT OUTSIDE POLICY → "unsupported".

      Plus the standard: "supported", "contradicted", "unsupported".

      Verdict: "pass" when all are supported, "fail" otherwise.

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
