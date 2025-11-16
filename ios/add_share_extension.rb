#!/usr/bin/env ruby

require 'xcodeproj'

# 프로젝트 열기
project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Runner 타겟 찾기
runner_target = project.targets.find { |target| target.name == 'Runner' }

# ShareExtension 타겟이 이미 있는지 확인
existing_target = project.targets.find { |target| target.name == 'ShareExtension' }

if existing_target
  puts "ShareExtension target already exists. Skipping..."
  exit 0
end

puts "Adding ShareExtension target..."

# ShareExtension 타겟 생성
share_extension_target = project.new_target(
  :app_extension,
  'ShareExtension',
  :ios,
  '13.0'
)

# ShareExtension 그룹 생성
share_extension_group = project.main_group.new_group('ShareExtension', 'ShareExtension')

# Base.lproj 그룹 생성
base_lproj_group = share_extension_group.new_group('Base.lproj', 'ShareExtension/Base.lproj')

# 파일 추가
swift_file = share_extension_group.new_file('ShareExtension/ShareViewController.swift')
info_plist = share_extension_group.new_file('ShareExtension/Info.plist')
entitlements = share_extension_group.new_file('ShareExtension/ShareExtension.entitlements')
storyboard = base_lproj_group.new_file('ShareExtension/Base.lproj/MainInterface.storyboard')

# Swift 파일을 타겟의 소스에 추가
share_extension_target.add_file_references([swift_file])

# Storyboard를 리소스에 추가
share_extension_target.resources_build_phase.add_file_reference(storyboard)

# Build Settings 설정
share_extension_target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'ShareExtension/Info.plist'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.minorlab.miniline.ShareExtension'
  config.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'ShareExtension/ShareExtension.entitlements'
  config.build_settings['DEVELOPMENT_TEAM'] = runner_target.build_configurations.first.build_settings['DEVELOPMENT_TEAM']
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
end

# Runner 타겟의 dependencies에 ShareExtension 추가
share_extension_target_dependency = runner_target.add_dependency(share_extension_target)

# Copy Files Build Phase 추가 (Extension을 앱 번들에 포함)
copy_files_phase = runner_target.new_copy_files_build_phase('Embed App Extensions')
copy_files_phase.symbol_dst_subfolder_spec = :plug_ins
copy_files_phase.add_file_reference(share_extension_target.product_reference)

# 프로젝트 저장
project.save

puts "ShareExtension target added successfully!"
puts "Please run 'pod install' to complete the setup."
