require "English"
require_relative "lib/jekyll-offload/version"

Gem::Specification.new do |s|
  s.name          = "jekyll-offload"
  s.version       = JekyllOffload::VERSION
  s.license       = "GPL-3.0"
  s.authors       = ["Joe Buhlig"]
  s.email         = ["joe@joebuhlig.com"]
  s.homepage      = "https://rubygems.org/gems/jekyll-offload"
  s.summary       = "A jekyll plugin that moves your assets to S3."
  s.description   = "A jekyll plugin that moves your assets to S3."
  s.files         = `git ls-files -z`.split("\x0").grep(%r!^lib/!)
  s.require_paths = ["lib"]
  s.metadata      = {
    "source_code_uri" => "https://github.com/joebuhlig/jekyll-offload",
    "bug_tracker_uri" => "https://github.com/joebuhlig/jekyll-offload/issues",
    "changelog_uri"   => "https://github.com/joebuhlig/jekyll-offload/releases",
    "homepage_uri"    => s.homepage,
  }
  s.add_dependency "jekyll", ">= 3.7", "< 5.0"
  s.add_dependency  "aws-sdk-s3"
  s.add_dependency "mime-types"
  s.add_dependency "mini_magick"
end
