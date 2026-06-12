# frozen_string_literal: true

require "ruby_llm/contract"

# Judge v2 — refined. Distinguishes stylistic courtesy (supported) from a
# commitment outside the policy (unsupported). This is the calibrated judge
# the production gate uses (evals.rb).
class FaithfulnessJudgeV2 < RubyLLM::Contract::Step::Base
  input_type Hash
  model "gpt-4.1-mini"
  temperature 0
  max_cost 0.005

  prompt do
    system <<~SYS
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

      Format: JSON {"claims":[{"claim":"...","status":"..."}],
                    "verdict":"pass|fail","reason":"krótko"}.
    SYS
    user <<~MSG
      ŹRÓDŁO:
      {source}

      ODPOWIEDŹ:
      {answer}
    MSG
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
  validate("werdykt zgodny ze statusami twierdzeń") do |o, _|
    has_bad = o[:claims].any? { |c| %w[contradicted unsupported].include?(c[:status]) }
    o[:verdict] == (has_bad ? "fail" : "pass")
  end
end
