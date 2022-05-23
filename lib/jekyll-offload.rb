require 'aws-sdk-s3'

module JekyllOffload
  def self.offload()
    s3 = Aws::S3::Client.new(
      access_key_id: ENV["S3_ACCESS_KEY"],
      secret_access_key: ENV["S3_SECRET_KEY"],
      endpoint: ENV["S3_OFFLOAD_ENDPOINT"],
      region: ENV["S3_OFFLOAD_REGION"]
    )

    Dir['media/**/*.*'].each do |file|
      puts "Uploading: #{file}"
      obj = Aws::S3::Object.new(client: s3, bucket_name: ENV["S3_OFFLOAD_BUCKET"], key: file)
      upload = obj.put({acl: "public-read", body: File.read(file)})
      File.delete(file)
    end
  end
end

require File.expand_path("jekyll/commands/offload.rb", __dir__)
