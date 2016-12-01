# Auto Texting

## Installation

`bundle install`

Copy `.env.example` to `.env` and replace with relevant values

## Parsing data from a spreadsheet

`bundle exec ruby pull-information.rb -h` to see options

Handles pulling down and parsing names and phone numbers out of
spreadsheets and outputting them into JSON files / uploading to
S3 as well as updating rows in the spreadsheet to mark them as
claimed.  See the options and prompts from the script to understand.

## Bulk messaging

`bundle exec ruby auto-text.rb -h` to see options

Handles sending messages in bulk to a set of numbers from an
input JSON file including substituting names.
