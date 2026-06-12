# frozen_string_literal: true
#
# Alternative to iterating the prompt: extend the source of truth. Same v3
# prompt, but it now reads SourceExtended.policy (which states the facts about
# discounts, exceptions, and equal treatment). Article section 6d.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "source_extended"
require "faq_step_v3_extended"
require "faithfulness_judge_v2"
require "adversarial"

puts "═" * 76
puts "Part 1: adversarial archetypes × v3 prompt + EXTENDED policy"
puts "═" * 76
puts ""

adv_pass = 0
Adversarial.cases.each_with_index do |adv, i|
  result = FaqStepV3Extended.run(adv[:question])
  next unless result.ok?

  answer = result.parsed_output[:answer]
  judge = FaithfulnessJudgeV2.run({ source: SourceExtended.policy, answer: answer })
  next unless judge.ok?

  verdict = judge.parsed_output[:verdict]
  adv_pass += 1 if verdict == "pass"
  marker = verdict == "pass" ? "✓ PASS" : "✗ FAIL"

  puts "Archetype #{i + 1} #{adv[:archetype]}: #{marker}"
  puts "  answer: #{answer[0..150]}#{answer.length > 150 ? '...' : ''}"
  puts "  reason: #{judge.parsed_output[:reason]}" if verdict == "fail"
  puts ""
end
puts "Adversarial: #{adv_pass}/#{Adversarial.cases.length} PASS"
puts ""

puts "═" * 76
puts "Part 2: regression control — reference questions"
puts "═" * 76
puts ""

FaqStepV3Extended.define_eval("faithfulness_extended") do
  SourceExtended.golden_questions.each_with_index do |question, i|
    add_case "case_#{i + 1}",
             input: question,
             evaluator: ->(output, _input) {
               verdict = FaithfulnessJudgeV2.run(
                 { source: SourceExtended.policy, answer: output[:answer] }
               )
               next 0.0 unless verdict.ok?

               verdict.parsed_output[:verdict] == "pass" ? 1.0 : 0.0
             }
  end
end

report = FaqStepV3Extended.run_eval("faithfulness_extended")
report.results.each do |c|
  marker = c.passed? ? "✓" : "✗"
  puts "  #{marker}  #{c.name.ljust(8)} score=#{c.score}"
end
puts ""
puts "Reference: score #{report.score} (#{report.passed? ? 'PASS' : 'FAIL'})"
puts ""

puts "═" * 76
puts "Lesson: instead of iterating the prompt from v3 to v4, you can extend"
puts "the source — same prompt, richer policy, better score."
puts "═" * 76
