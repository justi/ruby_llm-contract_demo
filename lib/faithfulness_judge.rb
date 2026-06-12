# frozen_string_literal: true

require "ruby_llm/contract"

# Judge v1 — raw version. Tags every claim as supported/contradicted/unsupported.
# Does not distinguish stylistic courtesy from a commitment → over-strict.
# Narrative starting point: the judge itself needs to be calibrated.
class FaithfulnessJudge < RubyLLM::Contract::Step::Base
  input_type Hash
  model "gpt-4.1-mini"
  temperature 0
  max_cost 0.005

  prompt do
    system <<~SYS
      Jesteś rzetelnym fact-checkerem. Otrzymujesz ŹRÓDŁO i ODPOWIEDŹ.
      Rozłóż ODPOWIEDŹ na atomowe twierdzenia. Dla każdego twierdzenia
      oznacz:
        - "supported"     — wynika ze ŹRÓDŁA
        - "contradicted"  — ŹRÓDŁO mówi przeciwnie
        - "unsupported"   — nie ma w ŹRÓDLE

      Werdykt: "pass" gdy wszystkie supported, "fail" w pozostałych
      przypadkach.

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

  # Cross-check: verdict has to match claim statuses (guards against the
  # judge returning "pass" with a contradicted claim in its own breakdown).
  validate("werdykt zgodny ze statusami twierdzeń") do |o, _|
    has_bad = o[:claims].any? { |c| %w[contradicted unsupported].include?(c[:status]) }
    o[:verdict] == (has_bad ? "fail" : "pass")
  end
end
