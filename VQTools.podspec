
Pod::Spec.new do |s|

  s.name         = "VQTools"
  s.version      = "0.0.1"
  s.summary      = "一些常用的工具方法的整合."

  s.description  = <<-DESC
                    整合了一些系统的拍照录音录像功能，及相册存取和其他相关便捷方法。
                   DESC

  s.homepage     = "https://github.com/vqboy/VQTools"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = { "VQBoy" => "519296460@qq.com" }

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/vqboy/VQTools.git", :tag => "#{s.version}" }


  s.source_files  = "VQTools/VQTools.{h,m}","VQTools/Lib/lame/lame.h"
  s.public_header_files = "VQTools/VQTools.h"

  s.preserve_paths = "VQTools/**/*.{h,m,a}"

  s.frameworks = "UIKit", "Foundation", "CoreTelephony", "AudioToolbox", "AVFoundation", "AssetsLibrary", "Photos", "CoreLocation", "MediaPlayer"

  s.ios.vendored_libraries = "VQTools/Lib/lame/libmp3lame.a"

  s.requires_arc = true

  s.xcconfig = { "ENABLE_BITCODE" => "NO" }
  s.dependency "AFNetworking", "~> 3.0.0"

end
