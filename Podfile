#
# The following environment variables are optional for you to control your build:
# AYLA_BUILD_BRANCH: default to the current branch
# AYLA_SDK_BRANCH: default to AYLA_BUILD_BRANCH
#
# if you want to build a branch other than your crrent branch, switch to that branch to build it;
# for public release we set lib branch by replacing $AYLA_BUILD_BRANCH with release/x.y.zz etc because
# their branch names are different; for internal repos, lib branches can be the same as build branch
# such as "develop" etc
#
# The following are for rare cases when you use a git protocol other than https or a different remote
# AYLA_PUBLIC: "" for internal, "_Public" for public repo, script can detect by itself unless you specify
# AYLA_SDK_REPO: default to https://github.com/AylaNetworks/iOS_AylaSDK(_Public).git
# AYLA_REMOTE: default to origin
#
# INCLUDE_WECHAT_OAUTH: define this variable to include and enable WeChat OAuth capability
#

require_relative './Podhelper'

#Configuration Section: you can change the following variables to configure your build
conditional_assign("ayla_build_branch", "") #"develop"
conditional_assign("ayla_sdk_branch", "release/5.6.02") #or @ayla_build_branch)
conditional_assign("ayla_sdk_repo", "") #"https://github.com/AylaNetworks/iOS_AylaSDK(_Public).git"
conditional_assign("ayla_public", "")
conditional_assign("ayla_remote", "origin")

conditional_assign("include_wechat_oauth", "")

# conext display: show value whenever related environment variables are set
build_var_array=["AYLA_BUILD_BRANCH", "AYLA_SDK_BRANCH", "AYLA_SDK_REPO", "AYLA_PUBLIC", "AYLA_REMOTE"]
build_var_array.each do |n|
    puts "Your #{n} is set to #{ENV[n]}" if ENV.has_key?(n) and !ENV[n].empty?;
end

branch_string=`git branch | grep "* "`
abort "No branch found." if $?.to_i != 0

cur_branch=branch_string.split(' ')[-1]

# default all branches to the current branch if they are still not set or empty
conditional_assign("ayla_build_branch", cur_branch)

cur_path=File.expand_path('.')
public_repo_path_pattern=/.*_Public$/
if public_repo_path_pattern =~ cur_path
    conditional_assign("ayla_public", "_Public")
    repo_type="public"
else
    repo_type="internal"
end

conditional_assign "ayla_sdk_repo", "https://github.com/AylaNetworks/iOS_AylaSDK#{@ayla_public}.git"

corresponding_sdk_branch=`git ls-remote #{@ayla_sdk_repo} | grep #{cur_branch}`
if corresponding_sdk_branch != ""
    puts "\nFound SDK branch: #{corresponding_sdk_branch}"
    conditional_assign("ayla_sdk_branch", cur_branch)
else
    default_sdk_branch = @ayla_public == "_Public" ? "master" : "develop"
    puts "\nNo SDK branch found matching your current branch name.  Using '#{default_sdk_branch}'. Define $AYLA_SDK_BRANCH to override."
    conditional_assign("ayla_sdk_branch", "#{default_sdk_branch}")
end

# hard-coded to be imported by Aura code. Both public and internal repo have to use this name
sdk_pod="iOS_AylaSDK"

puts "\n*** Building #{repo_type.try(:green)} repo on branch #{@ayla_build_branch.try(:green)} with sdk branch #{@ayla_sdk_branch.try(:green)} ***"
puts "*** sdk pod: #{sdk_pod.try(:green)} sdk repo: #{@ayla_sdk_repo.try(:green)} ***\n\n"

build_var_array.each do |v|
    puts "now #{v} = " + instance_variable_get("@#{v.downcase}").to_s
end

source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '8.4'

use_frameworks!

target :iOS_Aura do

    pod sdk_pod,
    :git => "#{@ayla_sdk_repo}", :branch => "#{@ayla_sdk_branch}"
    #:path => '../iOS_AylaSDK', :branch => "#{@ayla_sdk_branch}"

    pod 'SAMKeychain'
    pod 'PDKeychainBindingsController'
    pod 'ActionSheetPicker-3.0'
    pod 'Google/SignIn'
    pod 'MBProgressHUD'
    pod 'SideMenuController'
    if @include_wechat_oauth != ""
        # US Developers wishing to use WeChat OAuth may need to acquire the WechatOpenSDK files and associated podspec from Ayla Customer Success.
        pod 'WechatOpenSDK'#, :path => 'OpenSDK1.7.7'
    end
end

post_install do |installer|
  # Add compiler flags to import WeChat related files and enable code when and where required
  app_project = Xcodeproj::Project.open(Dir.glob("*.xcodeproj")[0])
  app_project.native_targets.each do |target|
  if target.name == 'iOS_Aura'
      target.build_configurations.each do |config|
        preproc_defs = config.build_settings['GCC_PREPROCESSOR_DEFINITIONS']
        swift_flags = config.build_settings['OTHER_SWIFT_FLAGS']
        if @include_wechat_oauth != ""
            # Remove flags
          swift_flags << " -DINCLUDE_WECHAT_OAUTH" unless swift_flags.include?(" -DINCLUDE_WECHAT_OAUTH")
          preproc_defs.delete("INCLUDE_WECHAT_OAUTH=0")
          preproc_defs << " INCLUDE_WECHAT_OAUTH=1" unless preproc_defs.include?("INCLUDE_WECHAT_OAUTH=1")
        else
        # Add flags
          swift_flags.slice!(" -DINCLUDE_WECHAT_OAUTH")
          preproc_defs.delete("INCLUDE_WECHAT_OAUTH=1")
          preproc_defs << " INCLUDE_WECHAT_OAUTH=0" unless preproc_defs.include?("INCLUDE_WECHAT_OAUTH=0")
        end
        app_project.save
      end
    end
  end
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << " DD_LEGACY_MACROS=1"
    config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
  end
end
