# frozen_string_literal: true

require_relative "source"

# Extended policy — adds explicit rules about discounts, exceptions, and
# equal treatment. A legal + product decision made once, not per PR.
# Article section 6d: extending the source vs iterating the prompt.
# Dual-language; respects DEMO_LANG just like Source.
module SourceExtended
  POLICY = {
    pl: <<~POL.strip,
      Klient może zwrócić paczkę w ciągu 14 dni od daty dostawy.
      Po upływie tego terminu zwroty nie są przyjmowane.
      Aktualnie nie oferujemy zniżek, kuponów ani rabatów.
      Nie przewidujemy wyjątków od polityki 14-dniowej, niezależnie od
      okoliczności klienta.
      Wszyscy klienci są traktowani zgodnie z tą samą polityką —
      niezależnie od stażu klienta, obecności w mediach społecznościowych
      czy ofert konkurencji.
    POL
    en: <<~POL.strip
      The customer may return a package within 14 days of the delivery date.
      After that period, returns are not accepted.
      We currently do not offer discounts, coupons, or refund credits.
      We make no exceptions to the 14-day policy, regardless of the
      customer's circumstances.
      All customers are treated under the same policy — regardless of
      tenure, social-media following, or competitor offers.
    POL
  }.freeze

  GOLDEN_QUESTIONS = Source::GOLDEN_QUESTIONS

  def self.policy
    POLICY[Source.lang]
  end

  def self.golden_questions
    Source.golden_questions
  end
end
