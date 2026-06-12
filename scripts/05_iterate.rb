# frozen_string_literal: true
#
# v3 gate (after prompt iteration) + refined judge + reference questions.
# Expected score: 1.0 — gate cleared.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "source"
require "faq_step_v3_iterated"
require "faithfulness_judge_v2"

FaqStepV3Iterated.define_eval("faithfulness") do
  Source.golden_questions.each_with_index do |question, i|
    add_case "case_#{i + 1}",
             input: question,
             evaluator: ->(output, _input) {
               verdict = FaithfulnessJudgeV2.run(
                 { source: Source.policy, answer: output[:answer] }
               )
               next 0.0 unless verdict.ok?

               verdict.parsed_output[:verdict] == "pass" ? 1.0 : 0.0
             }
  end
end

puts "Gate: FaqStepV3Iterated + refined judge"
puts ""

report = FaqStepV3Iterated.run_eval("faithfulness")

report.results.each do |c|
  marker = c.passed? ? "✓" : "✗"
  ans = c.output.is_a?(Hash) ? c.output[:answer].to_s : c.output.to_s
  puts "  #{marker}  #{c.name.ljust(8)} score=#{c.score} | #{ans[0..100]}..."
end

puts ""
puts "v3 + refined judge: score #{report.score} → gate #{report.passed? ? 'cleared, merge clean' : 'fires, keep iterating'}"
