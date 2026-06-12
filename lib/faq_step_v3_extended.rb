# frozen_string_literal: true

require "ruby_llm/contract"
require_relative "kb_extended"

# v3 prompt (unchanged) + extended policy (KbExtended). Shows that a richer
# source of truth reduces drift without iterating the prompt itself.
# Article section 6d.
class FaqStepV3Extended < RubyLLM::Contract::Step::Base
  input_type String
  model "gpt-4.1-mini"
  temperature 0
  max_cost 0.005

  prompt do
    system <<~SYS
      Odpowiadasz na pytanie klienta sklepu o politykę zwrotów.

      ZASADY:
      1. Bądź ciepły i empatyczny.
      2. NIE OBIECUJ niczego czego nie ma w POLITYCE:
         - nie sugeruj że "postaramy się znaleźć rozwiązanie",
         - nie obiecuj "elastyczności" ani "wyjątków",
         - nie deklaruj "zrobimy wszystko".
      3. Jeśli pytanie wykracza poza POLITYKĘ — powiedz wprost że nie
         masz takich informacji. KONIEC.

      POLITYKA:
      #{KbExtended::POLICY}

      Format odpowiedzi: JSON {"answer": "..."}.
    SYS
    user "{input}"
  end

  output_schema { string :answer }

  validate("odpowiedź jest niepusta") { |o, _| o[:answer].to_s.strip.length.positive? }
  validate("odpowiedź mieści się w karcie") { |o, _| o[:answer].length <= 400 }
end
