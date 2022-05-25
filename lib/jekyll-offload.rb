require 'aws-sdk-s3'
require 'mime-types'
require 'mini_magick'
require 'fileutils'

module JekyllOffload
  def self.offload()
    Dir['media/**/*.*'].each do |file|
      push_to_s3(file)
      File.delete("thumbnails/#{file}")
      File.delete("square/#{file}")
      File.delete(file)
    end
    FileUtils.remove_dir("thumbnails") if File.directory?("thumbnails")
    FileUtils.remove_dir("square") if File.directory?("square")
  end

  def self.push_to_s3(file)
    s3 = Aws::S3::Client.new(
      access_key_id: ENV["S3_ACCESS_KEY"],
      secret_access_key: ENV["S3_SECRET_KEY"],
      endpoint: ENV["S3_OFFLOAD_ENDPOINT"],
      region: ENV["S3_OFFLOAD_REGION"]
    )
    file_type = MIME::Types.type_for(file.split('.').last).first.to_s
    if file_type == "image/jpeg"
      path = File.dirname(file)
      FileUtils.mkdir_p("thumbnails/#{path}") unless File.directory?("thumbnails/#{path}")
      FileUtils.mkdir_p("square/#{path}") unless File.directory?("square/#{path}")
      puts "Creating thumbnail: thumbnails/#{file}"
      convert = MiniMagick::Tool::Magick.new
      convert << file
      convert.resize("x700")
      convert << "thumbnails/#{file}"
      convert.call
      obj = Aws::S3::Object.new(client: s3, bucket_name: ENV["S3_OFFLOAD_BUCKET"], key: "thumbnails/#{file}")
      upload = obj.put({acl: "public-read", body: File.read("thumbnails/#{file}"), content_type: file_type})
puts "Creating square: square/#{file}"
      convert = MiniMagick::Tool::Magick.new
      convert << file
      convert.merge! ["-thumbnail", "1080x1080^", "-gravity", "center", "-extent", "1080x1080", "-auto-orient"]
      convert << "square/#{file}"
      convert.call
      obj = Aws::S3::Object.new(client: s3, bucket_name: ENV["S3_OFFLOAD_BUCKET"], key: "square/#{file}")
      upload = obj.put({acl: "public-read", body: File.read("square/#{file}"), content_type: file_type})
    end
    puts "Uploading: #{file}"
    obj = Aws::S3::Object.new(client: s3, bucket_name: ENV["S3_OFFLOAD_BUCKET"], key: file)
    upload = obj.put({acl: "public-read", body: File.read(file), content_type: file_type})
    file
  end
end

require File.expand_path("jekyll/commands/offload.rb", __dir__)
