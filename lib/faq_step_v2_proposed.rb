# frozen_string_literal: true

require "ruby_llm/contract"
require_relative "kb"

# v2 — PR opened after the product manager asked for warmer replies.
# Good intentions, side effect: the model invents commitments outside policy.
#
# Changes vs v1 (faq_step.rb):
# - prompt: "EXCLUSIVELY from POLICY" → "Be warm, promise a flexible solution".
# - validate "brak prefiksu AI-disclaimer": **dropped** (intentional — "be warm"
#   removes robotic phrasing like "as an AI"). Length cap stays at 300 — the article
#   shows that 3/4 adversarial outputs exceeded 300 chars and the length validate
#   blocked them, giving a false sense of safety before the prompt was audited.
class FaqStepV2Proposed < RubyLLM::Contract::Step::Base
  input_type String
  model "gpt-4.1-mini"
  temperature 0
  max_cost 0.005

  prompt do
    system <<~SYS
      Odpowiadasz na pytanie klienta sklepu o politykę zwrotów.

      ZASADY:
      1. Bądź ciepły i empatyczny. Klient ma dobrego dnia.
      2. Jeśli klient pyta o coś trudnego (np. przegapiony termin) —
         zapewnij go że zrobisz wszystko żeby pomóc i znajdziesz
         elastyczne rozwiązanie.
      3. Używaj informacji z POLITYKI.

      POLITYKA:
      #{Kb::POLICY}

      Format odpowiedzi: JSON {"answer": "..."}.
    SYS
    user "{input}"
  end

  output_schema { string :answer }

  validate("odpowiedź jest niepusta") { |o, _| o[:answer].to_s.strip.length.positive? }
  validate("odpowiedź mieści się w karcie") { |o, _| o[:answer].length <= 300 }
end
