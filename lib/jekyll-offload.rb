require 'aws-sdk-s3'
require 'mime-types'
require 'mini_magick'
require 'fileutils'

module JekyllOffload
  def self.offload()
    s3 = Aws::S3::Client.new(
      access_key_id: ENV["S3_ACCESS_KEY"],
      secret_access_key: ENV["S3_SECRET_KEY"],
      endpoint: ENV["S3_OFFLOAD_ENDPOINT"],
      region: ENV["S3_OFFLOAD_REGION"]
    )

    Dir['media/**/*.*'].each do |file|
      file_type = MIME::Types.type_for(file.split('.').last).first.to_s
      if file_type == "image/jpeg"
        path = File.dirname(file)
        FileUtils.mkdir_p("thumbnails/#{path}") unless File.directory?("thumbnails/#{path}")
        puts "Creating thumbnail: thumbnails/#{file}"
        convert = MiniMagick::Tool::Magick.new
        convert << file
        convert.resize("x700")
        convert << "thumbnails/#{file}"
        convert.call
        obj = Aws::S3::Object.new(client: s3, bucket_name: ENV["S3_OFFLOAD_BUCKET"], key: "thumbnails/#{file}")
        upload = obj.put({acl: "public-read", body: File.read("thumbnails/#{file}"), content_type: file_type})
        File.delete("thumbnails/#{file}")
      end
      FileUtils.remove_dir("thumbnails")
      puts "Uploading: #{file}"
      obj = Aws::S3::Object.new(client: s3, bucket_name: ENV["S3_OFFLOAD_BUCKET"], key: file)
      upload = obj.put({acl: "public-read", body: File.read(file), content_type: file_type})
      File.delete(file)
    end
  end
end

require File.expand_path("jekyll/commands/offload.rb", __dir__)
