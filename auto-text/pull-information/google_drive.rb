require 'google_drive'

module PullInformation
  class Drive
    def initialize(config_path, spreadsheet_key)
      @session = GoogleDrive::Session.from_config(config_path)
      @doc = @session.spreadsheet_by_key(spreadsheet_key)
    end

    def title
      @doc.title
    end

    def num_rows(sheet_index)
      @doc.worksheets[sheet_index].num_rows
    end

    def num_cols(sheet_index)
      @doc.worksheets[sheet_index].num_cols
    end

    def sheets
      @doc.worksheets
    end

    def set_cell(sheet_index, row, col, val)
      @doc.worksheets[sheet_index][row, col] = val
    end

    def get_cell(sheet_index, row, col)
      @doc.worksheets[sheet_index][row, col]
    end

    def save(sheet_index)
      @doc.worksheets[sheet_index].save
    end
  end
end
