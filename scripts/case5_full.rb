# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "kb"
require "faq_step_v2_proposed"
require "faq_step_v3_iterated"

q = Kb.golden_questions[4]
puts "Q: #{q}"
puts ""

r2 = FaqStepV2Proposed.run(q)
puts "v2: #{r2.ok? ? r2.parsed_output[:answer] : "validation_failed: #{r2.validation_errors.inspect}"}"
puts ""

r3 = FaqStepV3Iterated.run(q)
puts "v3: #{r3.ok? ? r3.parsed_output[:answer] : "validation_failed: #{r3.validation_errors.inspect}"}"
