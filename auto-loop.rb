#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

CLI_PROFILES = {
  'copilot' => {
    defaults: %w[--allow-all-tools --disallow-temp-dir],
    build: lambda do |model, prompt, continue, flags|
      args = ['copilot', '--model', model]
      args += continue ? ['--continue', '--prompt', prompt] : ['--prompt', prompt]
      args + flags + ['--silent']
    end
  },
  'claude' => {
    defaults: %w[--dangerously-skip-permissions],
    build: lambda do |model, prompt, continue, flags|
      args = ['claude', '-p', '--model', model]
      args << '--continue' if continue
      args + flags + [prompt]
    end
  }
}.freeze

models = nil
prompt = nil
validate = nil
group_pattern = nil
after_group = nil
reuse = false
cli = 'copilot'

OptionParser.new do |opts|
  opts.on('--cli NAME', "CLI to use (#{CLI_PROFILES.keys.join(', ')})") { |v| cli = v }
  opts.on('--model MODELS', 'Model(s) to use (comma-separated for S/M/L/XL)') do |v|
    models = v.split(',').map(&:strip)
  end
  opts.on('--prompt TEXT', 'Prompt prefix for each line') { |v| prompt = v }
  opts.on('--validate CMD', 'Validation command (retries until passing)') { |v| validate = v }
  opts.on('--group-pattern PAT', 'Regex to match group headers') { |v| group_pattern = Regexp.new(v) }
  opts.on('--after-group CMD', 'Command to run after each group') { |v| after_group = v }
  opts.on('--reuse', 'Reuse CLI session within each group') { reuse = true }
end.order!

abort 'Missing --model and --prompt' unless models && prompt
profile = CLI_PROFILES[cli] or abort "Unknown CLI: #{cli}. Use: #{CLI_PROFILES.keys.join(', ')}"

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
cli_flags = ARGV.empty? ? profile[:defaults] : ARGV.dup

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

  warn "[#{count += 1}:#{SIZE_MAP.key(marker) || 'M'}:#{model}] #{cleaned_line}"
  full_prompt = "#{prompt} #{cleaned_line}"
  full_prompt += ". Validate completion with: #{validate}" if validate
  use_continue = reuse && group_tasks.any?
  first_attempt = true
  loop do
    task_prompt = full_prompt
    unless first_attempt
      output = `#{validate} 2>&1`
      task_prompt = "#{full_prompt}\n\nValidation `#{validate}` failed with output:\n#{output}\nFix and retry."
    end
    args = profile[:build].call(model, task_prompt, use_continue || !first_attempt, cli_flags)
    first_attempt = false
    use_continue = true
    system(*args) or exit(1)
    break if !validate || system(validate)
  end
  group_tasks << cleaned_line
end

run_group.call
