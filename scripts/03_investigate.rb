# frozen_string_literal: true
#
# Per-case analysis of the raw judge against v2 answers.
# Shows why the judge flags politeness as drift — and which flags are
# legitimate (a commitment outside the policy).

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "kb"
require "faq_step_v2_proposed"
require "faithfulness_judge"

Kb::GOLDEN_QUESTIONS.each_with_index do |question, idx|
  puts "═" * 76
  puts "case_#{idx + 1}  Q: #{question}"
  puts "═" * 76

  answer_result = FaqStepV2Proposed.run(question)
  unless answer_result.ok?
    puts "  FaqStep status: #{answer_result.status}, errors: #{answer_result.validation_errors}"
    puts ""
    next
  end

  answer = answer_result.parsed_output[:answer]
  puts "Answer:"
  puts "  #{answer}"
  puts ""

  judge_result = FaithfulnessJudge.run({ source: Kb::POLICY, answer: answer })
  unless judge_result.ok?
    puts "  Judge status: #{judge_result.status}, errors: #{judge_result.validation_errors}"
    puts ""
    next
  end

  out = judge_result.parsed_output
  puts "Verdict: #{out[:verdict].upcase}"
  puts "Reason:  #{out[:reason]}"
  puts ""
  puts "Claims:"
  out[:claims].each do |c|
    marker = case c[:status]
             when "supported"     then "  ✓"
             when "contradicted"  then "  ✗"
             when "unsupported"   then "  ?"
             end
    puts "#{marker} [#{c[:status].ljust(13)}] #{c[:claim]}"
  end
  puts ""
end
