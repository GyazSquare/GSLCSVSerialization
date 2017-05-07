Pod::Spec.new do |s|
  s.name         = 'GSLCSVSerialization'
  s.version      = '1.1.0'
  s.author       = 'GyazSquare'
  s.license      = { :type => 'MIT' }
  s.homepage     = 'https://github.com/GyazSquare/GSLCSVSerialization'
  s.source       = { :git => 'https://github.com/GyazSquare/GSLCSVSerialization.git', :tag => 'v1.1.0' }
  s.summary      = 'An Objective-C CSV parser for iOS, OS X, watchOS and tvOS.'
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.6'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  s.requires_arc  = true
  s.source_files  = 'GSLCSVSerialization/*.{h,m}'
end
