# frozen_string_literal: true
#
# BONUS - the same gate, off-the-shelf, via ruby_llm-tribunal.
#
# Catalog vs custom. Scripts 01-10 walk through *building* a faithfulness
# judge from scratch (Step 1 build -> Step 2 calibrate -> Step 3 gate).
# This spec answers the question that comes right after: "do I really
# have to write all that code if I just need a faithfulness check?"
#
# Tribunal ships built-in judges (assert_faithful, refute_hallucination,
# assert_no_pii, ...) with baked-in prompts. Trade-off:
#
#   + zero LOC for the judge itself - the catalog ships it
#   + no initial prompt to iterate
#   - default threshold (0.8) and prompt are domain-agnostic;
#     your domain may need calibration anyway
#   - cannot teach Tribunal the courtesy-vs-commitment distinction
#     that the custom judge learns in 04_refined_judge.rb
#     ("Happy to help" = stylistic, supported; "we'll find a solution"
#      = commercial promise, unsupported)
#
# Companion guide: docs/guide/llm_judge.md "When to reach for Tribunal"
# + docs/guide/relation_to_tribunal.md in the gem repo.
#
# ⚠️ Live OpenAI calls (Tribunal's judge is itself an LLM).
# ⚠️ Tribunal's exact include path (RubyLLM::Tribunal::EvalHelpers) may
#     differ across versions - check `gem which ruby_llm-tribunal` and
#     the gem's README if RSpec reports an undefined `assert_faithful`.
#
# Run: LIVE=1 bundle exec rspec spec/tribunal_comparison_spec.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "ruby_llm/tribunal"
require "kb"
require "faq_step"
require "faq_step_v2_proposed"

RSpec.describe "Tribunal: off-the-shelf faithfulness gate" do
  include RubyLLM::Tribunal::EvalHelpers

  let(:context) { [Kb.policy] }

  # v1 - production baseline. No drift, Tribunal should pass it.
  describe "FaqStep (v1, production)" do
    Kb.golden_questions.each_with_index do |question, idx|
      it "case #{idx + 1}: #{question}" do
        response = FaqStep.run(question).parsed_output[:answer]
        assert_faithful response, context: context
      end
    end
  end

  # v2 - the "be warm" PR. Drifts into commercial promises.
  # Marked :drifted so the suite passes overall; remove the filter (or
  # delete `pending`) to see Tribunal flag the regression without you
  # having written a single line of judge code.
  describe "FaqStepV2Proposed (PR drift)", :drifted do
    Kb.golden_questions.each_with_index do |question, idx|
      it "case #{idx + 1}: #{question}" do
        pending "Demonstration: Tribunal's catalog judge flags the same " \
                "drift the custom judge catches in 04_refined_judge.rb. " \
                "Remove `pending` to see RSpec report the failure."
        response = FaqStepV2Proposed.run(question).parsed_output[:answer]
        assert_faithful response, context: context
      end
    end
  end
end
