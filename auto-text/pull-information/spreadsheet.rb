require 'phone'

module PullInformation
  module Spreadsheet
    def self.parse(doc)
      puts "Found document: #{doc.title}"
      sheet_index = self.get_sheet_index(doc)
      self.get_sheet_layout(doc, sheet_index)
    end

    def self.claim_rows(doc, data)
      sheet = doc.sheets[data[:sheet_index]]
      claim_column = data[:claim_column]

      print 'Where should claiming begin? '
      claim_start_row = gets.to_i

      print 'How many rows should be claimed? '
      claim_count = gets.to_i

      print 'What should the claim value be? '
      claim_value = gets.to_s.strip

      puts "Claiming rows #{claim_start_row} through #{claim_start_row + claim_count - 1}"
      (0...claim_count).each do |offset|
        row = claim_start_row + offset
        val = sheet[row, claim_column]

        if !val.empty? && val != claim_value
          puts "Found value: '#{val}' at (#{row}, #{claim_column}), not overwriting"
        else
          sheet[row, claim_column] = claim_value
        end
      end

      puts 'Persisting...'
      sheet.save
      return {
        claim_count: claim_count,
        claim_start_row: claim_start_row
      }
    end

    def self.extract_phone_numbers(doc, data)
      Phoner::Phone.default_country_code = data[:country_code] || '1'

      sheet = doc.sheets[data[:sheet_index]]
      puts "Num Rows: #{sheet.num_rows}"
      (data[:first_row]..sheet.num_rows).reduce({}) do |accum, row|
        phone = sheet[row, data[:phone_column]]
        name = sheet[row, data[:name_column]]

        if phone.empty? || name.empty?
          puts "Invalid row #{row}"
        elsif !Phoner::Phone.valid? phone
          puts "Invalid phone number #{phone} in row #{row}, skipping"
        else
          parsed_number = Phoner::Phone.parse(phone)
          accum[parsed_number.to_s] = {
            name: name,
            row: row
          }
        end

        accum
      end
    end

    def self.get_sheet_layout(doc, index)
      limited_rows = [doc.num_rows(index), 10].min
      sheet = doc.sheets[index]

      (1..limited_rows).each do |row|
        row_text = (1..sheet.num_cols)
          .map { |col| sheet[row, col] }
          .join(', ')

        puts "#{row}) #{row_text}"
      end

      print 'Select row where phone numbers start: '
      first_phone_row = gets.to_i

      print 'Select column containing phone numbers: '
      phone_column = gets.to_i

      print 'Select column containing names: '
      name_column = gets.to_i

      print 'Select column containing claims: '
      claim_column = gets.to_i

      return {
        sheet_index: index,
        first_row: first_phone_row,
        phone_column: phone_column,
        name_column: name_column,
        claim_column: claim_column
      }
    end

    def self.get_sheet_index(doc)
      sheet_index = nil

      while !sheet_index
        puts "\nChoose a sheet to operate on"

        doc.sheets.each_with_index do |sheet, index|
          puts "#{index}) #{sheet.title}"
        end

        num = gets.to_i

        if num >= 0 && num < doc.sheets.length
          sheet_index = num
        else
          puts "Invalid selection"
        end
      end

      puts "Selected #{doc.sheets[sheet_index].title}"
      return sheet_index
    end
  end
end
