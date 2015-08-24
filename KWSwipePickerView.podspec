Pod::Spec.new do |s|
  s.name                = "KWSwipePickerView"
  s.version             = "1.1"
  s.summary             = "Expendable Swipe View!"
  s.homepage            = "http://github.com/Kawoou/KWSwipePickerView"
  s.license             = { :type => 'MIT', :file => 'LICENSE' }
  s.author              = { "Kawoou" => "kawoou@kawoou.kr" }
  s.source              = { :git => "https://github.com/Kawoou/KWSwipePickerView.git", :tag => "#{s.version}" }
  s.platform            = :ios, 7.0
  s.public_header_files = 'KWSwipePickerView/KWSwipePickerView/KWSwipePickerView.h'
  s.frameworks          = 'UIKit', 'Foundation', 'QuartzCore'
  s.requires_arc        = true
  s.source_files        = 'KWSwipePickerView/KWSwipePickerView/*'
end
