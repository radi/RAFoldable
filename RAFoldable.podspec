Pod::Spec.new do |s|
  s.name         = "RAFoldable"
  s.version      = "0.0.1"
  s.summary      = "Foldable View Controller Constructs."
  s.homepage     = "http://github.com/evadne/RAFoldable"
  s.license      = 'MIT'
  s.author       = { "Evadne Wu" => "ev@radi.ws" }
  s.source       = { :git => "https://github.com/evadne/RAFoldable.git", :tag => "0.0.1" }
  s.platform     = :ios, '6.0'
	s.source_files = 'RAFoldable', 'Classes/**/*.{h,m}'
  s.exclude_files = 'RAFoldable/Exclude'
  s.frameworks  = 'QuartzCore'
  s.requires_arc = true
  s.dependency 'AGGeometryKit', '~> 0.1.5'
	s.dependency 'RANudgable'
end
