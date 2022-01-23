# Uncomment the next line to define a global platform for your project
use_frameworks!
platform :ios, '12.0'

def shared_pods
#  pod 'FanapPodChatSDK'
  pod 'FanapPodAsyncSDK', :path => '/Users/hamed/Desktop/WorkSpace/ios/Fanap/Fanap-Async-SDK'
  pod 'FanapPodChatSDK', :path => '/Users/hamed/Desktop/WorkSpace/ios/Fanap/Fanap-Chat-SDK'
end

target 'ChatApplication' do
  shared_pods
end

target 'MyWidgetExtension' do
    shared_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Disable bitcode in order to support FanapPodChatSDK
      if target.name == "FanapPodChatSDK" then
#        config.build_settings['ENABLE_BITCODE'] = 'NO'
        config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
      end
    end
  end
end
