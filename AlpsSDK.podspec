Pod::Spec.new do |s|
  s.name = 'AlpsSDK'
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.9'
  s.version = '0.0.3'
  s.authors = 'Alps Team'
  s.homepage = 'http://matchmore.io/alps'
  s.summary = 'Alps iOS SDK in Swift'
  s.source = { :git => 'https://github.com/MatchMore/alps-ios-sdk.git', :tag => s.version }
  s.license = 'BSD 3-Clause License'
  s.source_files = 'AlpsSDK/**/*.swift'
  s.dependency 'Alps'
end
