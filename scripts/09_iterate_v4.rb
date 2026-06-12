# frozen_string_literal: true
#
# v4 (after adversarial iteration) — tested in two parts:
#   1. 4 adversarial archetypes → 4/4 PASS
#   2. 5 reference questions    → 5/5 PASS (no regression)

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "kb"
require "faq_step_v4_iterated"
require "faithfulness_judge_v2"
require "adversarial"

puts "═" * 76
puts "Part 1: adversarial archetypes × v4 + refined judge"
puts "═" * 76
puts ""

adv_pass = 0
Adversarial::CASES.each_with_index do |adv, i|
  result = FaqStepV4Iterated.run(adv[:question])
  next unless result.ok?

  answer = result.parsed_output[:answer]
  judge = FaithfulnessJudgeV2.run({ source: Kb::POLICY, answer: answer })
  next unless judge.ok?

  verdict = judge.parsed_output[:verdict]
  adv_pass += 1 if verdict == "pass"
  marker = verdict == "pass" ? "✓ PASS" : "✗ FAIL"

  puts "Archetype #{i + 1} #{adv[:archetype]}: #{marker}"
  puts "  v4 answer: #{answer[0..150]}#{answer.length > 150 ? '...' : ''}"
  puts "  reason:    #{judge.parsed_output[:reason]}" if verdict == "fail"
  puts ""
end

puts "Adversarial: #{adv_pass}/#{Adversarial::CASES.length} PASS"
puts ""

puts "═" * 76
puts "Part 2: regression control — reference questions"
puts "═" * 76
puts ""

FaqStepV4Iterated.define_eval("faithfulness") do
  Kb::GOLDEN_QUESTIONS.each_with_index do |question, i|
    add_case "case_#{i + 1}",
             input: question,
             evaluator: ->(output, _input) {
               verdict = FaithfulnessJudgeV2.run(
                 { source: Kb::POLICY, answer: output[:answer] }
               )
               next 0.0 unless verdict.ok?

               verdict.parsed_output[:verdict] == "pass" ? 1.0 : 0.0
             }
  end
end

report = FaqStepV4Iterated.run_eval("faithfulness")
report.results.each do |c|
  marker = c.passed? ? "✓" : "✗"
  puts "  #{marker}  #{c.name.ljust(8)} score=#{c.score}"
end
puts ""
puts "Reference: score #{report.score} (#{report.passed? ? 'PASS' : 'FAIL'})"
puts ""

puts "═" * 76
puts "v4 cycle:  adversarial #{adv_pass}/#{Adversarial::CASES.length}, reference #{report.score}"
puts "═" * 76
