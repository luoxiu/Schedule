Pod::Spec.new do |s|
  s.name             = "Schedule"
  s.version          = "1.0.0"
  s.summary          = "A lightweight task scheduler for Swift."
  s.description      = <<-DESC
                       Schedule is a missing lightweight task scheduler for Swift.
                       It allows you run timed tasks using an incredibly human-friendly syntax.
                       DESC
  s.homepage         = "https://github.com/jianstm/Schedule"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Quentin Jin" => "jianstm@gmail.com" }
  s.source           = { :git => "https://github.com/jianstm/Schedule.git",
                         :tag => "#{s.version}" }
  s.source_files     = "Sources/Schedule/*.swift"
  s.requires_arc     = true
  s.swift_version    = "4.2"

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.tvos.deployment_target = "9.0"
  s.watchos.deployment_target = "2.0"
end
