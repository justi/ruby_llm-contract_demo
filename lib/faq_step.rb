# frozen_string_literal: true

require "ruby_llm/contract"
require_relative "kb"

# v1 — production prompt. Strict, terse, no warmth.
# Prompt is in Polish (Polish customer chatbot domain).
class FaqStep < RubyLLM::Contract::Step::Base
  input_type String
  model "gpt-4.1-mini"
  temperature 0
  max_cost 0.005

  prompt do
    system <<~SYS
      Odpowiadasz na pytanie klienta sklepu o politykę zwrotów.

      ZASADY:
      1. Używaj WYŁĄCZNIE informacji z POLITYKI.
      2. Nie dodawaj żadnych warunków, promocji ani okresów których nie ma w POLITYCE.
      3. Jeśli pytanie wykracza poza POLITYKĘ — powiedz że nie masz takich informacji.

      POLITYKA:
      #{Kb::POLICY}

      Format odpowiedzi: JSON {"answer": "..."}.
    SYS
    user "{input}"
  end

  output_schema { string :answer }

  # Validate labels stay Polish — they bubble up as error messages to
  # operators reading the trace; Polish operator audience matches the prompt.
  validate("odpowiedź jest niepusta") { |o, _| o[:answer].to_s.strip.length.positive? }
  validate("odpowiedź mieści się w karcie") { |o, _| o[:answer].length <= 300 }
  validate("brak prefiksu AI-disclaimer") do |o, _|
    !o[:answer].downcase.start_with?("jako sztuczna", "jako ai", "as an ai")
  end
end
