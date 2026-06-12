# frozen_string_literal: true

require "ruby_llm/contract"
require_relative "source"
require_relative "source_extended"

# v3 prompt (unchanged) + extended policy (SourceExtended). Shows that a richer
# source of truth reduces drift without iterating the prompt itself.
# Article section 6d.
class FaqStepV3Extended < RubyLLM::Contract::Step::Base
  SYSTEM_PROMPTS = {
    pl: <<~SYS,
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
      %{policy}

      Format odpowiedzi: JSON {"answer": "..."}.
    SYS
    en: <<~SYS
      You are answering a customer's question about the return policy of a store.

      RULES:
      1. Be warm and empathetic.
      2. DO NOT PROMISE anything not in the POLICY:
         - do not suggest "we will try to find a solution",
         - do not promise "flexibility" or "exceptions",
         - do not declare "we will do everything".
      3. If the question goes beyond the POLICY — say plainly that you
         don't have that information. END THERE.

      POLICY:
      %{policy}

      Response format: JSON {"answer": "..."}.
    SYS
  }.freeze

  input_type String
  model "gpt-4.1-mini"
  temperature 0
  max_cost 0.005

  prompt do
    system format(SYSTEM_PROMPTS[Source.lang], policy: SourceExtended.policy)
    user "{input}"
  end

  output_schema { string :answer }

  validate("answer is non-empty") { |o, _| o[:answer].to_s.strip.length.positive? }
  validate("answer fits the card") { |o, _| o[:answer].length <= 400 }
end
