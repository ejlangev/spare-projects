require 'optparse'
require 'pp'
require 'dotenv'

require './pull-information/google_drive'
require './pull-information/spreadsheet'
require './pull-information/upload_to_s3'

Dotenv.load

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: pull-information.rb [options]"

  opts.on('-f', '--file FILE', 'Required Google File Id') do |f|
    options[:file] = f
  end

  opts.on('-s', '--save', 'Whether to persist these names and numbers to S3') do |s|
    options[:save] = s
  end

  opts.on('-c', '--claim', 'Whether or not to claim rows') do |c|
    options[:claim] = true
  end

  opts.on('-o', '--output PATH', 'Where to write the JSON data for the claimed numbers') do |o|
    options[:output] = o;
  end
end.parse!

doc = PullInformation::Drive.new('.google.json', options[:file])
sheet_info = PullInformation::Spreadsheet.parse(doc)
all_values = PullInformation::Spreadsheet.extract_phone_numbers(
  doc, sheet_info.merge(country_code: ENV['default_country_code'])
)

all_numbers = all_values.reduce({}) do |accum, (key, val)|
  accum[key] = val[:name]
  accum
end

claimed_info = {}

if options[:claim]
  claimed_data = PullInformation::Spreadsheet.claim_rows(
    doc, sheet_info
  )

  puts claimed_data

  start_row = claimed_data[:claim_start_row]
  (start_row...start_row + claimed_data[:claim_count]).each do |row|
    number, data = all_values.find { |key, val| val[:row] == row }

    if !data
      puts "Nothing found for row #{row}"
    else
      claimed_info[number] = data[:name]
    end
  end
end

if options[:save]
  today = Date.today
  filename = "#{today.year}-#{today.month}-#{today.day}.json"
  full_filename = "/#{ENV['PHONE_NUMBER_S3_FOLDER']}/#{filename}"

  PullInformation::S3.upload(
    full_filename,
    all_numbers,
    access_key: ENV['AWS_ACCESS_KEY'],
    secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
    bucket: ENV['PHONE_NUMBER_S3_BUCKET']
  )

  filename = "#{today.year}-#{today.month}.json"
  full_filename = "/#{ENV['PHONE_NUMBER_S3_FOLDER']}/#{filename}"

  PullInformation::S3.upload(
    full_filename,
    all_numbers,
    access_key: ENV['AWS_ACCESS_KEY'],
    secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
    bucket: ENV['PHONE_NUMBER_S3_BUCKET']
  )

  tomorrow = Date.today + 1
  filename = "#{tomorrow.year}-#{tomorrow.month}-#{tomorrow.day}.json"
  full_filename = "/#{ENV['PHONE_NUMBER_S3_FOLDER']}/#{filename}"

  PullInformation::S3.upload(
    full_filename,
    all_numbers,
    access_key: ENV['AWS_ACCESS_KEY'],
    secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
    bucket: ENV['PHONE_NUMBER_S3_BUCKET']
  )
end

if options[:output]
  if !claimed_info.empty?
    File.open(options[:output], 'w') do |file|
      file.write(JSON.unparse(claimed_info))
    end
  else
    puts "Nothing claimed to output"
  end
end
