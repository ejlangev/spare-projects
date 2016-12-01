require 'uber-s3'
require 'date'
require 'json'

module PullInformation
  module S3
    def self.upload(filename, data, opts = {})
      s3 = UberS3.new(
        access_key: opts[:access_key],
        secret_access_key: opts[:secret_access_key],
        bucket: opts[:bucket],
        adapter: :net_http
      )

      puts "Saving data to S3 under #{filename}"
      existing_data = {}

      if s3.exists?(filename)
        puts "Updating existing file"
        object = s3.object(filename)
        existing_data = JSON.parse(object.value)
        object.value = JSON.unparse(existing_data.merge(data))
        object.save
      else
        puts "Creating new file"
        s3.store(filename, JSON.unparse(data))
      end

      puts "Completed"
    end
  end
end
