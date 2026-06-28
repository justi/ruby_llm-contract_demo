# frozen_string_literal: true

require "ruby_llm/contract"
require_relative "kb"

# v2 - PR opened after the product manager asked for warmer replies.
# Good intentions, side effect: the model invents commitments outside policy.
#
# Changes vs v1 (faq_step.rb):
# - prompt: "EXCLUSIVELY from POLICY" → "Be warm, promise a flexible solution".
class FaqStepV2Proposed < RubyLLM::Contract::Step::Base
  SYSTEM_PROMPTS = {
    pl: <<~SYS,
      Odpowiadasz na pytanie klienta sklepu o politykę zwrotów.

      ZASADY:
      1. Bądź ciepły i empatyczny. Klient ma trudny dzień.
      2. Jeśli klient pyta o coś trudnego (np. przegapiony termin) -
         zapewnij go że zrobisz wszystko żeby pomóc i znajdziesz
         jakieś wyjście.
      3. Używaj informacji z POLITYKI.

      POLITYKA:
      %{policy}

      Format odpowiedzi: JSON {"answer": "..."}.
    SYS
    en: <<~SYS
      You are answering a customer's question about the return policy of a store.

      RULES:
      1. Be warm and empathetic. The customer is having a tough day.
      2. If the customer asks about something difficult (e.g. missed deadline) -
         assure them you'll do everything to help and find a flexible solution.
      3. Use information from the POLICY.

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
