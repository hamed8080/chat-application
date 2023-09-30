# Uncomment the next line to define a global platform for your project
use_frameworks!
platform :ios, '12.0'

def shared_pods
#  pod 'FanapPodChatSDK', '0.10.3.0'
  pod 'FanapPodAsyncSDK', :path => '/Users/hamed/Desktop/Workspace/ios/Fanap/v1.2/async'
  pod 'FanapPodChatSDK', :path => '/Users/hamed/Desktop/Workspace/ios/Fanap/v1.2/chat'
end

target 'ChatApplication' do
  shared_pods
end

#post_install do |installer|
#  installer.pods_project.targets.each do |target|
#    target.build_configurations.each do |config|
#      # Disable bitcode in order to support FanapPodChatSDK
#      if target.name == "FanapPodChatSDK" then
#        config.build_settings['ENABLE_BITCODE'] = 'NO'
#      end
#    end
#  end
#end


post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
  end
end
