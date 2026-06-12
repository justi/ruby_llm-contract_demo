# frozen_string_literal: true

require_relative "kb"

# Extended policy — adds explicit rules about discounts, exceptions, and equal
# treatment. A legal + product decision, made once, not per PR.
# Article section 6d: extending source vs iterating the prompt.
module KbExtended
  POLICY = <<~POL.strip
    Klient może zwrócić paczkę w ciągu 14 dni od daty dostawy.
    Po upływie tego terminu zwroty nie są przyjmowane.
    Aktualnie nie oferujemy zniżek, kuponów ani rabatów.
    Nie przewidujemy wyjątków od polityki 14-dniowej, niezależnie od
    okoliczności klienta.
    Wszyscy klienci są traktowani zgodnie z tą samą polityką —
    niezależnie od stażu klienta, obecności w mediach społecznościowych
    czy ofert konkurencji.
  POL

  GOLDEN_QUESTIONS = Kb::GOLDEN_QUESTIONS
end
