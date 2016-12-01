require 'twilio-ruby'
require 'dotenv'
require 'json'
require 'optparse'

Dotenv.load

from_number = ENV['DEFAULT_FROM_NUMBER']
base_vars = {
  my_name: ENV['MY_FIRST_NAME']
}

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: auto-text.rb [options]"

  opts.on('-d', '--dry-run', 'Do not actually send text messages') do |d|
    options[:dry_run] = d
  end

  opts.on('-i', '--input PATH', 'Input JSON file to read phone information from') do |i|
    options[:input] = i
  end

  opts.on('-b', '--body PATH', 'Optional file to read text body information from') do |b|
    options[:body] = b
  end
end.parse!

if !options[:input]
  raise 'Input is a required param'
end

def get_client
  @client ||= Twilio::REST::Client.new(
    ENV['TWILIO_ACCOUNT_SID'],
    ENV['TWILIO_AUTH_TOKEN']
  )
end

def send_message(body, to, from, dry_run = true)
  if !dry_run
    get_client.account.messages.create(body: body, to: to, from: from)
    puts "Sent to #{to}"
  else
    puts "Mocking message from #{from} to #{to}: #{body}"
  end
end

raw_data = File.open(options[:input]).gets
numbers = JSON.parse(raw_data)
raw_body = nil

if options[:body]
  raw_body = File.open(options[:body]).gets.strip
else
  puts "Enter a body for the message:"
  raw_body = gets("\n\n\n").strip
end

one_week_ago = Time.now - (7 * 24 * 60 * 60)
messages_this_week = get_client.messages.list('start_time>' => one_week_ago)

numbers.each_pair do |key, val|
  first_name = val.split(' ')[0]
  vars = { first_name: first_name }.merge(base_vars)
  substituted_body = raw_body % vars

  if messages_this_week.any? { |msg| msg.to == key && msg.body == substituted_body }
    puts "Already messaged #{val}"
    next
  end

  send_message(substituted_body, key, from_number, options[:dry_run])
end
