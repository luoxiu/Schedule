Pod::Spec.new do |s|
  s.name             = "Schedule"
  s.version          = "2.0.0-beta.1"
  s.license          = { :type => "MIT" }
  s.homepage         = "https://github.com/jianstm/Schedule"
  s.author           = { "Quentin Jin" => "jianstm@gmail.com" }
  s.summary          = "Lightweight timing task scheduler"

  s.source           = { :git => "https://github.com/jianstm/Schedule.git", :tag => "#{s.version}" }
  s.source_files     = "Sources/Schedule/*.swift"
  
  s.swift_version    = "4.2"

  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.12"
  s.tvos.deployment_target = "10.0"
  s.watchos.deployment_target = "3.0"
end
