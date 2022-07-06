require 'aws-sdk-s3'
require 'mime-types'
require 'mini_magick'
require 'fileutils'
require 'git'

module JekyllOffload
  def self.offload()
    conf = Jekyll.configuration['jekyll_offload'].dup
    conf.each do |dir|
      files = get_files(dir)
      puts files
      files.each do |file|
        destination = ((dir.has_key? "destination") ? (file.sub(dir['source'], dir['destination'])) : (file))
        push_to_s3(file, destination, dir['thumbnails'], dir['square'])
        if dir['delete']
          File.delete("thumbnails/#{file}") if File.file?("thumbnails/#{file}")
          File.delete("square/#{file}") if File.file?("square/#{file}")
          File.delete(file)
        end
      end
    end
  end

  def self.get_files(conf)
    if conf["changed"]
      to_push = []
      @status = Git.open('.').status unless @status
      Dir["#{conf['source']}/**/*.*"].each do |file|
        if @status.added?(file) || @status.changed?(file) || @status.untracked?(file)
          to_push.push(file)
        end
      end
      to_push
    else
      Dir["#{conf['source']}/**/*.*"]
    end
  end

  def self.push_to_s3(file, destination, thumbnail = false, square = false)
    s3 = Aws::S3::Client.new(
      access_key_id: ENV["S3_ACCESS_KEY"],
      secret_access_key: ENV["S3_SECRET_KEY"],
      endpoint: ENV["S3_OFFLOAD_ENDPOINT"],
      region: ENV["S3_OFFLOAD_REGION"]
    )
    file_type = MIME::Types.type_for(file.split('.').last).first.to_s
    if file_type == "image/jpeg" or file_type == "image/png"
      path = File.dirname(file)
      FileUtils.mkdir_p("thumbnails/#{path}") unless File.directory?("thumbnails/#{path}")
      FileUtils.mkdir_p("square/#{path}") unless File.directory?("square/#{path}")

      if thumbnail
        puts "Creating thumbnail: thumbnails/#{destination}"
        convert = MiniMagick::Tool::Convert.new
        convert << file
        convert.resize("352x198")
        convert.resample("72")
        convert << "thumbnails/#{destination}"
        convert.call
        obj = Aws::S3::Object.new(client: s3, bucket_name: ENV["S3_OFFLOAD_BUCKET"], key: "thumbnails/#{destination}")
        upload = obj.put({acl: "public-read", body: File.read("thumbnails/#{destination}"), content_type: file_type})
      end

      if square
        puts "Creating square: square/#{destination}"
        image = MiniMagick::Image.open(file)
        shortside = image.dimensions.sort.first
        convert = MiniMagick::Tool::Convert.new
        convert << file
        convert.merge! ["-thumbnail", "#{shortside}x#{shortside}^", "-gravity", "center", "-extent", "#{shortside}x#{shortside}", "-auto-orient"]
        convert << "square/#{destination}"
        convert.call
        obj = Aws::S3::Object.new(client: s3, bucket_name: ENV["S3_OFFLOAD_BUCKET"], key: "square/#{destination}")
        upload = obj.put({acl: "public-read", body: File.read("square/#{destination}"), content_type: file_type})
      end
    end
    puts "Uploading: #{file}"
    obj = Aws::S3::Object.new(client: s3, bucket_name: ENV["S3_OFFLOAD_BUCKET"], key: destination)
    upload = obj.put({acl: "public-read", body: File.read(file), content_type: file_type})
    file
  end
end

require File.expand_path("jekyll/commands/offload.rb", __dir__)
