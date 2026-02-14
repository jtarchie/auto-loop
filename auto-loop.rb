#!/usr/bin/env ruby
require "optparse"

model = nil
prompt = nil
validate = nil
group_pattern = nil
after_group = nil

OptionParser.new do |opts|
  opts.on("--model NAME", "Copilot model to use") { |v| model = v }
  opts.on("--prompt TEXT", "Prompt prefix for each line") { |v| prompt = v }
  opts.on("--validate CMD", "Validation command (retries until passing)") { |v| validate = v }
  opts.on("--group-pattern PAT", "Regex to match group headers") { |v| group_pattern = Regexp.new(v) }
  opts.on("--after-group CMD", "Command to run after each group") { |v| after_group = v }
end.order!

abort "Missing --model and --prompt" unless model && prompt

ARGV.shift if ARGV.first == "--"
copilot_flags = ARGV.empty? ? %w[--allow-all-tools --disallow-temp-dir] : ARGV.dup

count = 0
group_count = 0

run_group = lambda do
  return unless after_group && group_count > 0

  warn "[after-group] #{after_group}"
  system(after_group) or exit(1)
  group_count = 0
end

$stdin.each_line(chomp: true) do |line|
  next if line.strip.empty?

  if group_pattern&.match?(line)
    run_group.call
    warn "[group] #{line}"
    next
  end

  warn "[#{count += 1}] #{line}"
  loop do
    full_prompt = "#{prompt} #{line}"
    full_prompt += ". Validate completion with: #{validate}" if validate
    if system("copilot", "--model", model, "--prompt", full_prompt, *copilot_flags, "--silent")
      break if !validate || system(validate)
    end
    exit(1) unless validate
  end
  group_count += 1
end

run_group.call
