# frozen_string_literal: true

require "ruby_llm/contract"
require_relative "kb"

# v1 — production prompt. Strict, terse, no warmth.
# Dual-language prompts; respects DEMO_LANG just like Kb.
class FaqStep < RubyLLM::Contract::Step::Base
  SYSTEM_PROMPTS = {
    pl: <<~SYS,
      Odpowiadasz na pytanie klienta sklepu o politykę zwrotów.

      ZASADY:
      1. Używaj WYŁĄCZNIE informacji z POLITYKI.
      2. Nie dodawaj żadnych warunków, promocji ani okresów których nie ma w POLITYCE.
      3. Jeśli pytanie wykracza poza POLITYKĘ — powiedz że nie masz takich informacji.

      POLITYKA:
      %{policy}

      Format odpowiedzi: JSON {"answer": "..."}.
    SYS
    en: <<~SYS
      You are answering a customer's question about the return policy of a store.

      RULES:
      1. Use ONLY the information from the POLICY.
      2. Do not add any conditions, promotions, or periods not present in the POLICY.
      3. If the question goes beyond the POLICY — say you don't have that information.

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
    system format(SYSTEM_PROMPTS[Kb.lang], policy: Kb.policy)
    user "{input}"
  end

  output_schema { string :answer }
end
