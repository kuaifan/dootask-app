Pod::Spec.new do |s|
  s.name         = "WeexPluginLoader"
  s.version      = "0.0.1.9.1"
  s.summary      = "Source-compatible Weex plugin loader."
  s.description  = "Source-compatible Weex plugin loader for arm64 simulator builds."
  s.homepage     = "http://eeui.cc"
  s.license      = "MIT"
  s.author       = { "dootask" => "support@dootask.com" }
  s.source       = { :path => "." }
  s.source_files = "WeexPluginLoader/**/*.{h,m}"
  s.platform     = :ios, "8.0"
  s.requires_arc = true

  s.dependency "WeexSDK"
end
