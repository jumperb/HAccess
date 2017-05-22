
Pod::Spec.new do |s|

  s.name         = "HAccess"
  s.version      = "2.3.2"
  s.summary      = "A short description of HAccess."

  s.description  = <<-DESC
                   A longer description of HAccess in Markdown format.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.homepage     = "https://github.com/jumperb/HAccess"

  s.license      = "Copyright"
  
  s.author       = { "jumperb" => "zhangchutian_05@163.com" }

  s.source       = { :git => "https://github.com/jumperb/HAccess.git", :tag => s.version.to_s}
  
  s.requires_arc = true

  s.ios.deployment_target = '7.0'

  s.default_subspec = 'Network'

  s.subspec 'Entity' do |ss|
      ss.dependency "Hodor/Defines"
      ss.dependency "Hodor/Feature"
	  ss.dependency "Hodor/NS-Category"
      ss.ios.source_files = 'Classes/Entity/*.{h,m,mm,cpp,c}'
  end

  s.subspec 'Network' do |ss|
      ss.dependency "Hodor/Defines"
      ss.dependency "Hodor/Feature"
	  ss.dependency "Hodor/NS-Category"
      ss.dependency 'AFNetworking' ,'~>2.0'
      ss.dependency 'HCache'
      ss.dependency 'HAccess/Entity'
      ss.ios.source_files = 'Classes/Network/*.{h,m,mm,cpp,c}'
  end
  
  s.subspec 'Database' do |ss|
      ss.dependency "Hodor/Defines"
      ss.dependency "Hodor/Feature"
	  ss.dependency "Hodor/NS-Category"
      ss.dependency 'FMDB'
      ss.dependency 'HAccess/Entity'
      ss.ios.source_files = 'Classes/Database/*.{h,m,mm,cpp,c}'
  end

  s.subspec 'Network+Protobuf' do |ss|
      ss.dependency 'HAccess/Network'
      ss.dependency 'protocol-for-objectivec'
      ss.ios.source_files = 'Classes/Network+Protobuf/**/*.{h,m,mm,cpp,c}'
  end

end
