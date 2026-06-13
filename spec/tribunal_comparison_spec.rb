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
# Companion guides (in the ruby_llm-contract repo, not the Tribunal repo):
# docs/guide/llm_judge.md "When to reach for Tribunal" +
# docs/guide/relation_to_tribunal.md.
#
# Note on input fidelity: Tribunal's Faithful prompt templates a
# `## Question` slot (lib/ruby_llm/tribunal/judges/faithful.rb in the
# Tribunal gem source). This spec deliberately does NOT pass `query:`
# because the custom judges in lib/faithfulness_judge*.rb only see
# source + answer - sending the question to Tribunal would give the
# catalog judge MORE context than the custom one, and break apples-to-
# apples. Real Tribunal users should pass `query:` for RAG flows.
#
# ⚠️ Live OpenAI calls (Tribunal's judge is itself an LLM).
# ⚠️ Tribunal's stock default model is `anthropic:claude-3-5-haiku-latest`.
#     The configure block below overrides it to `openai:gpt-4.1-mini` so
#     this spec runs on the same OPENAI_API_KEY the rest of the demo uses.
#     If you remove the override, export ANTHROPIC_API_KEY too.
#
# Run: LIVE=1 bundle exec rspec spec/tribunal_comparison_spec.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "ruby_llm/tribunal"
require "kb"
require "faq_step"
require "faq_step_v2_proposed"

# Match the rest of the demo: OpenAI, gpt-4.1-mini, verbose so each
# case prints the judge's score + verdict on the console.
RubyLLM::Tribunal.configure do |c|
  c.default_model = "openai:gpt-4.1-mini"
  c.verbose       = true
end

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
  #
  # What to expect when you run this:
  #   Tribunal reliably flags loud commercial commitments ("we'll find a
  #   flexible solution"). The verdict on softer warmth ("happy to assist",
  #   "feel free to ask") varies run-to-run depending on how the v2 prompt
  #   phrases its courtesy. The custom judge in lib/faithfulness_judge_v2.rb
  #   flags both consistently because its prompt encodes the courtesy-vs-
  #   commitment distinction; the catalog prompt does not. That swing is
  #   the calibration gap - the point of this bonus spec.
  #
  # Tagged :drifted so default `bundle exec rspec` keeps the suite green.
  # Run `--tag drifted` to see the real verdicts:
  #
  #   LIVE=1 bundle exec rspec spec/tribunal_comparison_spec.rb --tag drifted
  describe "FaqStepV2Proposed (PR drift)", :drifted do
    Kb.golden_questions.each_with_index do |question, idx|
      it "case #{idx + 1}: #{question}" do
        response = FaqStepV2Proposed.run(question).parsed_output[:answer]
        assert_faithful response, context: context
      end
    end
  end
end
