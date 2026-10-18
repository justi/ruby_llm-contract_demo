source "https://rubygems.org"

gem "ruby_llm-contract", "~> 1.5"

group :development, :test do
  gem "rspec", "~> 3.13"

  # The bonus comparison spec (spec/tribunal_comparison_spec.rb) needs
  # ruby_llm-tribunal, which requires ruby_llm 1.x (0.1.1: ruby_llm ~> 1.0).
  # ruby_llm-contract 1.x runs on ruby_llm 2.x, so the two cannot share a
  # bundle and the spec skips itself. To run it, use the last ruby_llm 1.x
  # setup (ruby_llm-contract "~> 0.10.6") and add gem "ruby_llm-tribunal".
end
