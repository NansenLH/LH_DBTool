#
# Be sure to run `pod lib lint LH_DBTool.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LH_DBTool'
  s.version          = '12'
  s.summary          = '基于 FMDB 封装的数据库'
  s.homepage         = 'https://github.com/NansenLH/LH_DBTool'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'NansenLH' => 'nansen_lu@163.com' }
  s.source           = { :git => 'https://github.com/NansenLH/LH_DBTool.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.source_files = 'LH_DBTool/Classes/**/*'
  s.module_name = 'LH_DBTool'

  s.frameworks = 'UIKit'

  s.dependency 'FMDB'
  s.dependency 'YYModel'

end
