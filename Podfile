platform :ios, '13.0'

target 'Hiyo' do
  use_frameworks!

  # Masonry for Auto Layout
  pod 'Masonry', '1.1.0'

  # Networking - use AFNetworking for Objective-C
  pod 'AFNetworking', '4.0.1'


  # 嵌套滚动框架
  pod 'JXPagingView/Paging', '~> 2.1.2' # 嵌套滚动容器
  pod 'JXSegmentedView', '~> 1.3.0' # Tab分段控件
  pod 'MJRefresh', '3.7.5'# 滑动列表加载
  pod 'SDWebImage', '5.10.2'# 图片缓存管理
  pod 'SSZipArchive', '2.4.2'# zip解压

  pod 'MMKV', '1.3.5'
  pod 'MMKVCore', '1.3.5'
  pod 'FSPagerView', '~> 0.8.3'  # 卡片轮播控件
  pod 'ZLSwipeableView', :git => 'https://github.com/zhxnlai/ZLSwipeableView.git'  # OC版Tinder卡片
  #pod 'GoogleSignIn', '7.1.0'# Google登录
  #pod 'FBSDKCoreKit', '16.3.1'# Facebook Core SDK
  #pod 'FBSDKLoginKit', '16.3.1'# Facebook Login SDK

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['SWIFT_VERSION'] = '5.0'
    end
  end
end
