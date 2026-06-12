# frozen_string_literal: true
#
# The CI gate. Production class must keep faithfulness score ≥ 0.9 across
# the golden set. Any PR that drops the score below this bar fails CI
# and cannot merge.
#
# ⚠️  This spec hits real OpenAI API. Set LIVE=1 to confirm.
# Run: LIVE=1 bundle exec rspec spec/faithfulness_gate_spec.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "ruby_llm/contract/rspec"
require "evals"

RSpec.describe "faithfulness gate" do
  # The production class — this is what CI gates on every PR.
  it "FaqStep (production v1) passes the gate" do
    expect(FaqStep).to pass_eval("faithfulness").with_minimum_score(0.9)
  end

  # The proposed change — demonstrates the gate blocking a regression.
  # Marked `pending` so the suite passes overall; remove `pending` to see
  # the gate fire on the drifted prompt.
  it "FaqStepV2Proposed (PR drift) FAILS the gate", :drifted do
    pending "Demonstration: this is the regression the gate blocks. " \
            "Remove `pending` to see RSpec report the failure."
    expect(FaqStepV2Proposed).to pass_eval("faithfulness").with_minimum_score(0.9)
  end
end
