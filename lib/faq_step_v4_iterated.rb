# frozen_string_literal: true

require "ruby_llm/contract"
require_relative "kb"

# v4 — iteration after the adversarial tests. Adds a ban on the model
# constructing its own meta-justifications (e.g. "the policy is the same
# for all customers").
#
# Changes vs v3 (faq_step_v3_iterated.rb):
# - prompt: new RULE 4 — no constructing meta-justifications.
#   v3 failed on adversarial case 08 (reputational blackmail) where it invented
#   a meta-rule "policy is uniform for all customers". v4 explicitly bans this.
# - length cap: 400 unchanged.
# - validates: identical to v3.
class FaqStepV4Iterated < RubyLLM::Contract::Step::Base
  input_type String
  model "gpt-4.1-mini"
  temperature 0
  max_cost 0.005

  prompt do
    system <<~SYS
      Odpowiadasz na pytanie klienta sklepu o politykę zwrotów.

      ZASADY:
      1. Bądź ciepły i empatyczny. Klient ma trudny dzień. Możesz użyć
         pozdrowienia i wyrażenia zrozumienia.
      2. NIE OBIECUJ niczego czego nie ma w POLITYCE. W szczególności:
         - nie sugeruj że "postaramy się znaleźć rozwiązanie",
         - nie obiecuj "elastyczności" ani "wyjątków",
         - nie deklaruj "zrobimy wszystko" ani podobnych gestów.
      3. Jeśli pytanie wykracza poza POLITYKĘ — powiedz wprost że nie
         masz takich informacji. KONIEC. Nie dodawaj "ale skontaktuj
         się z BOK", "ale chętnie pomogę".
      4. Gdy odmawiasz lub odpowiadasz na trudne pytanie, podaj
         WYŁĄCZNIE fakt z POLITYKI. NIE konstruuj własnych meta-uzasadnień
         ani zasad ogólnych (np. "polityka jest jednakowa dla wszystkich
         klientów", "nie przewidujemy wyjątków") nawet jeśli brzmią
         rozsądnie i są prawdopodobnie prawdą. Jeśli POLITYKA czegoś nie
         mówi wprost — Ty też nie powinieneś.

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
