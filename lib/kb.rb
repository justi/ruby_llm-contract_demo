# frozen_string_literal: true

# Source of truth: one return-policy statement + a set of real customer
# questions. Dual-language (PL/EN) - pick the language via the DEMO_LANG
# env var (defaults to "en"). Code, comments, validate labels and CLI
# output stay English regardless of DEMO_LANG; only the domain strings switch.
module Kb
  POLICY = {
    pl: "Klient może zwrócić paczkę w ciągu 14 dni od daty dostawy. " \
        "Po upływie tego terminu zwroty nie są przyjmowane.",
    en: "The customer may return a package within 14 days of the delivery " \
        "date. After that period, returns are not accepted."
  }.freeze

  GOLDEN_QUESTIONS = {
    pl: [
      "Ile mam czasu na zwrot paczki?",
      "Czy mogę oddać produkt po 20 dniach?",
      "Od kiedy liczy się termin zwrotu?",
      "Czy zwroty są darmowe?",
      "Co jeśli przegapię termin zwrotu?"
    ].freeze,
    en: [
      "How long do I have to return a package?",
      "Can I return the product after 20 days?",
      "When does the return deadline start counting?",
      "Are returns free of charge?",
      "What if I miss the return deadline?"
    ].freeze
  }.freeze

  # Active language for this run (default: en). Uses DEMO_LANG (not LANG)
  # to avoid conflict with the system locale ("en_US.UTF-8" etc.).
  def self.lang
    sym = ENV.fetch("DEMO_LANG", "en").to_sym
    POLICY.key?(sym) ? sym : :en
  end

  def self.policy
    POLICY[lang]
  end

  def self.golden_questions
    GOLDEN_QUESTIONS[lang]
  end
end
