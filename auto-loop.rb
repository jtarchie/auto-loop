#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'shellwords'

models = nil
prompt = nil
validate = nil
group_pattern = nil
after_group = nil

OptionParser.new do |opts|
  opts.on('--model MODELS', 'Copilot model(s) to use (comma-separated for S/M/L/XL)') do |v|
    models = v.split(',').map(&:strip)
  end
  opts.on('--prompt TEXT', 'Prompt prefix for each line') { |v| prompt = v }
  opts.on('--validate CMD', 'Validation command (retries until passing)') { |v| validate = v }
  opts.on('--group-pattern PAT', 'Regex to match group headers') { |v| group_pattern = Regexp.new(v) }
  opts.on('--after-group CMD', 'Command to run after each group') { |v| after_group = v }
end.order!

abort 'Missing --model and --prompt' unless models && prompt

SIZE_MAP = { 'S' => 0, 'M' => 1, 'L' => 2, 'XL' => 3 }.freeze

select_model = ->(size) { models[size.zero? ? 0 : (size * (models.size - 1) / 3.0).ceil] }

extract_marker = lambda do |line|
  if (m = line.match(/\[(S|M|L|XL)\]\s*/i))
    [SIZE_MAP[m[1].upcase], line.sub(m[0], '')]
  else
    [1, line]
  end
end

ARGV.shift if ARGV.first == '--'
copilot_flags = ARGV.empty? ? %w[--allow-all-tools --disallow-temp-dir] : ARGV.dup

interpolate_cmd = lambda do |cmd, group, tasks|
  cmd.gsub('{{GROUP}}', Shellwords.escape(group || ''))
     .gsub('{{TASKS}}', Shellwords.escape(tasks.join("\n")))
end

count = 0
group_count = 0
current_group = nil
group_tasks = []

run_group = lambda do
  return unless after_group && group_count.positive?

  after_group_cmd = interpolate_cmd.call(after_group, current_group, group_tasks)
  warn "[after-group] #{after_group_cmd}"
  system(after_group_cmd) or exit(1)
  group_count = 0
  group_tasks = []
end

$stdin.each_line(chomp: true) do |line|
  next if line.strip.empty?

  if group_pattern&.match?(line)
    run_group.call
    current_group = line
    warn "[group] #{line}"
    next
  end

  marker, cleaned_line = extract_marker.call(line)
  model = select_model.call(marker)
  size_label = SIZE_MAP.key(marker) || 'M'

  warn "[#{count += 1}] [#{size_label}] #{cleaned_line}"
  full_prompt = "#{prompt} #{cleaned_line}"
  full_prompt += ". Validate completion with: #{validate}" if validate
  first_attempt = true
  loop do
    args = ['copilot', '--model', model]
    if first_attempt
      args += ['--prompt', full_prompt]
      first_attempt = false
    else
      output = `#{validate} 2>&1`
      args += ['--continue', '--prompt',
               "#{full_prompt}\n\nValidation `#{validate}` failed with output:\n#{output}\nFix and retry."]
    end
    args += [*copilot_flags, '--silent']
    copilot_succeeded = system(*args)
    exit(1) unless copilot_succeeded
    break if !validate || system(validate)
  end
  group_tasks << cleaned_line
  group_count += 1
end

run_group.call
