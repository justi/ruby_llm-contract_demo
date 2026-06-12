# frozen_string_literal: true
#
# v2 gate + raw judge. Shows the raw judge flagging every politeness as drift
# → 5/5 fail. Starting point for judge calibration.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "source"
require "faq_step_v2_proposed"
require "faithfulness_judge"

FaqStepV2Proposed.define_eval("faithfulness_raw_judge") do
  Source.golden_questions.each_with_index do |question, i|
    add_case "case_#{i + 1}",
             input: question,
             evaluator: ->(output, _input) {
               verdict = FaithfulnessJudge.run(
                 { source: Source.policy, answer: output[:answer] }
               )
               next 0.0 unless verdict.ok?

               verdict.parsed_output[:verdict] == "pass" ? 1.0 : 0.0
             }
  end
end

puts "Gate: FaqStepV2Proposed (PR 'be warm') + raw judge"
puts ""

report = FaqStepV2Proposed.run_eval("faithfulness_raw_judge")

report.results.each do |case_result|
  marker = case_result.passed? ? "✓" : "✗"
  ans = case_result.output.is_a?(Hash) ? case_result.output[:answer].to_s : case_result.output.to_s
  puts "  #{marker}  #{case_result.name.ljust(8)} score=#{case_result.score} | #{ans[0..100]}..."
end

puts ""
puts "Score: #{report.score}  Verdict: #{report.passed? ? 'PASS' : 'FAIL'}"
puts ""
puts "When score < 0.9 — the CI gate blocks the PR merge."
