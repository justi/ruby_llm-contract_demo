# frozen_string_literal: true

require "ruby_llm/contract"
require_relative "kb"

# v3 — iteration after feedback from the refined judge.
# Keeps the warmth, adds an explicit ban on promising outside the policy.
#
# Changes vs v2 (faq_step_v2_proposed.rb):
# - prompt: explicit "DO NOT PROMISE anything not in the POLICY" with a list
#   of concrete anti-phrases the judge pointed to in 04_refined_judge.rb.
# - prompt: explicit ban on promising outside the policy.
class FaqStepV3Iterated < RubyLLM::Contract::Step::Base
  SYSTEM_PROMPTS = {
    pl: <<~SYS,
      Odpowiadasz na pytanie klienta sklepu o politykę zwrotów.

      ZASADY:
      1. Bądź ciepły i empatyczny. Klient ma trudny dzień.
         Możesz użyć pozdrowienia i wyrażenia zrozumienia.
      2. NIE OBIECUJ niczego czego nie ma w POLITYCE. W szczególności:
         - nie sugeruj że "postaramy się znaleźć rozwiązanie",
         - nie obiecuj "ustępstw" ani "wyjątków",
         - nie deklaruj "zrobimy wszystko" ani podobnych gestów,
         - nie dodawaj informacji o kosztach, terminach ani warunkach
           których nie ma w POLITYCE.
      3. Jeśli pytanie wykracza poza POLITYKĘ — powiedz wprost że nie
         masz takich informacji. KONIEC. Nie dodawaj "ale skontaktuj
         się z BOK", "ale chętnie pomogę", "ale postaramy się".

      POLITYKA:
      %{policy}

      Format odpowiedzi: JSON {"answer": "..."}.
    SYS
    en: <<~SYS
      You are answering a customer's question about the return policy of a store.

      RULES:
      1. Be warm and empathetic. The customer is having a rough day.
         You may use a greeting and acknowledge their feelings.
      2. DO NOT PROMISE anything not in the POLICY. In particular:
         - do not suggest "we will try to find a solution",
         - do not promise "flexibility" or "exceptions",
         - do not declare "we will do everything" or similar gestures,
         - do not add information about costs, deadlines, or conditions
           that aren't in the POLICY.
      3. If the question goes beyond the POLICY — say plainly that you
         don't have that information. END THERE. Do not add "but contact
         support", "but I'm happy to help", "but we'll try".

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
