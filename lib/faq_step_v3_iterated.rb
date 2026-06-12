# frozen_string_literal: true

require "ruby_llm/contract"
require_relative "kb"

# v3 — iteration after feedback from the refined judge.
# Keeps the warmth, adds an explicit ban on promising outside the policy.
#
# Changes vs v2 (faq_step_v2_proposed.rb):
# - prompt: explicit "DO NOT PROMISE anything not in the POLICY" with a list of
#   concrete anti-phrases the judge pointed to in 04_refined_judge.rb.
# - length cap: 300 → 400 (warm replies with empathy need more room; the v1/v2 cap
#   of 300 was a leftover from the defensive first prompt).
class FaqStepV3Iterated < RubyLLM::Contract::Step::Base
  input_type String
  model "gpt-4.1-mini"
  temperature 0
  max_cost 0.005

  prompt do
    system <<~SYS
      Odpowiadasz na pytanie klienta sklepu o politykę zwrotów.

      ZASADY:
      1. Bądź ciepły i empatyczny. Klient ma trudny dzień.
         Możesz użyć pozdrowienia i wyrażenia zrozumienia.
      2. NIE OBIECUJ niczego czego nie ma w POLITYCE. W szczególności:
         - nie sugeruj że "postaramy się znaleźć rozwiązanie",
         - nie obiecuj "elastyczności" ani "wyjątków",
         - nie deklaruj "zrobimy wszystko" ani podobnych gestów,
         - nie dodawaj informacji o kosztach, terminach ani warunkach
           których nie ma w POLITYCE.
      3. Jeśli pytanie wykracza poza POLITYKĘ — powiedz wprost że nie
         masz takich informacji. KONIEC. Nie dodawaj "ale skontaktuj
         się z BOK", "ale chętnie pomogę", "ale postaramy się".

      POLITYKA:
      #{Kb::POLICY}

      Format odpowiedzi: JSON {"answer": "..."}.
    SYS
    user "{input}"
  end

  output_schema { string :answer }

  validate("odpowiedź jest niepusta") { |o, _| o[:answer].to_s.strip.length.positive? }
  validate("odpowiedź mieści się w karcie") { |o, _| o[:answer].length <= 400 }
end
