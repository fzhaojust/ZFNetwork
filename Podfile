platform :ios, '16.0'
use_frameworks!
target 'ZFNetworkDemo' do
  pod 'AFNetworking', '~> 3.0'
  pod 'SnapKit'
  pod 'Masonry'
  pod 'Mantle'
  pod 'YYText'
  pod 'YYCache'
end


post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
               end
          end
   end
end