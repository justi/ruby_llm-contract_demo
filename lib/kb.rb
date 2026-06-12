# frozen_string_literal: true

# Source of truth: one return-policy statement + a set of real customer questions.
# Business content is Polish (this demo simulates a Polish e-commerce chatbot).
module Kb
  POLICY = "Klient może zwrócić paczkę w ciągu 14 dni od daty dostawy. " \
           "Po upływie tego terminu zwroty nie są przyjmowane."

  GOLDEN_QUESTIONS = [
    "Ile mam czasu na zwrot paczki?",
    "Czy mogę oddać produkt po 20 dniach?",
    "Od kiedy liczy się termin zwrotu?",
    "Czy zwroty są darmowe?",
    "Co jeśli przegapię termin zwrotu?"
  ].freeze
end
