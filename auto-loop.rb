#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

models = nil
prompt = nil
validate = nil
group_pattern = nil
after_group = nil
reuse = false

OptionParser.new do |opts|
  opts.on('--model MODELS', 'Copilot model(s) to use (comma-separated for S/M/L/XL)') do |v|
    models = v.split(',').map(&:strip)
  end
  opts.on('--prompt TEXT', 'Prompt prefix for each line') { |v| prompt = v }
  opts.on('--validate CMD', 'Validation command (retries until passing)') { |v| validate = v }
  opts.on('--group-pattern PAT', 'Regex to match group headers') { |v| group_pattern = Regexp.new(v) }
  opts.on('--after-group CMD', 'Command to run after each group') { |v| after_group = v }
  opts.on('--reuse', 'Reuse copilot session within each group') { reuse = true }
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

escape_sq = ->(s) { s.gsub("'", "'\"'\"'") }

interpolate_cmd = lambda do |cmd, group, tasks|
  cmd.gsub('{{GROUP}}', escape_sq.call(group || ''))
     .gsub('{{TASKS}}', escape_sq.call(tasks.join("\n")))
end

count = 0
current_group = nil
group_tasks = []

run_group = lambda do
  return unless after_group && group_tasks.any?

  cmd = interpolate_cmd.call(after_group, current_group, group_tasks)
  warn "[after-group] #{cmd}"
  system(cmd) or exit(1)
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

  warn "[#{count += 1}] [#{SIZE_MAP.key(marker) || 'M'}] #{cleaned_line}"
  full_prompt = "#{prompt} #{cleaned_line}"
  full_prompt += ". Validate completion with: #{validate}" if validate
  use_continue = reuse && group_tasks.any?
  loop do
    args = ['copilot', '--model', model]
    if use_continue
      output = group_tasks.last == cleaned_line ? '' : `#{validate} 2>&1`
      retry_msg = output.empty? ? '' : "\n\nValidation `#{validate}` failed with output:\n#{output}\nFix and retry."
      args += ['--continue', '--prompt', "#{full_prompt}#{retry_msg}"]
    else
      args += ['--prompt', full_prompt]
    end
    use_continue = true
    args += [*copilot_flags, '--silent']
    system(*args) or exit(1)
    break if !validate || system(validate)
  end
  group_tasks << cleaned_line
end

run_group.call
