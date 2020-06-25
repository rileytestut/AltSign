Pod::Spec.new do |spec|
  spec.name         = "AltSign"
  spec.version      = "0.1"
  spec.summary      = "Open source iOS code-signing framework."
  spec.description  = "iOS framework to manage Apple developer accounts and resign apps."
  spec.homepage     = "https://github.com/rileytestut/altsign"
  spec.license      = "MIT"
  spec.platform     = :ios, "12.0"
  spec.source       = { :git => "https://github.com/rileytestut/AltSign.git" }

  spec.author             = { "Riley Testut" => "riley@rileytestut.com" }
  spec.social_media_url   = "https://twitter.com/rileytestut"
  
  spec.source_files  = "AltSign", "AltSign/**/*.{h,m,mm,hpp,cpp}"
  spec.public_header_files = "AltSign/**/*.h"
  spec.resources = "AltSign/Resources/apple.pem"
  spec.library = "c++"
  
  spec.xcconfig = {
    "OTHER_CFLAGS" => "-DCORECRYPTO_DONOT_USE_TRANSPARENT_UNION=1"
  }
  
  # Somewhat hacky subspec usage to ensure directory hierarchies match what header includes expect.
  
  spec.subspec 'OpenSSL' do |base|
    base.source_files  = "Dependencies/OpenSSL/ios/include/openssl/*.h"
    base.header_mappings_dir = "Dependencies/OpenSSL/ios/include"
    base.private_header_files = "Dependencies/OpenSSL/ios/include/openssl/*.h"
    base.vendored_libraries = "Dependencies/OpenSSL/ios/lib/libcrypto.a", "Dependencies/OpenSSL/ios/lib/libssl.a"
  end
  
  spec.subspec 'ldid' do |base|
    base.source_files = "AltSign/ldid/*.{hpp,h,c,cpp}", "Dependencies/ldid/*.{hpp,h,c,cpp}"
    base.private_header_files = "AltSign/ldid/*.hpp", "Dependencies/ldid/*.{hpp,h}"
    base.header_mappings_dir = ""
  end
  
  spec.subspec 'plist' do |base|
    base.source_files  = "Dependencies/ldid/libplist/include/plist/*.h", "Dependencies/ldid/libplist/src/*.{c,cpp}", "Dependencies/ldid/libplist/libcnary/**/*.{h,c}"
    base.exclude_files = "Dependencies/ldid/libplist/include/plist/String.h", "Dependencies/ldid/libplist/include/plist/Node.h" # Conflict with string.h and node.h, so exclude them.
    base.private_header_files = "Dependencies/ldid/libplist/include/plist/*.h", "Dependencies/ldid/libplist/libcnary/**/*.h"
    base.header_mappings_dir = "Dependencies/ldid/libplist"
    
    # Add libplist include directory so we can still find String.h and Node.h when explicitly requested.
    base.xcconfig = { "HEADER_SEARCH_PATHS" => '"$(SRCROOT)/../Dependencies/AltSign/Dependencies/ldid/libplist/include" "$(SRCROOT)/../Dependencies/AltSign/Dependencies/ldid/libplist/src"' }
  end
  
  spec.subspec 'minizip' do |base|
    base.source_files  = "Dependencies/minizip/*.{h,c}"
    base.exclude_files = "Dependencies/minizip/iowin32.*", "Dependencies/minizip/minizip.c", "Dependencies/minizip/miniunz.c"
    base.private_header_files = "Dependencies/minizip/*.h"
    base.header_mappings_dir = "Dependencies"
  end
  
  spec.subspec 'CoreCrypto' do |base|
    base.source_files  = "Dependencies/corecrypto/*.{h,m}"
    base.exclude_files = "Dependencies/corecrypto/ccperf.h"
    base.private_header_files = "Dependencies/corecrypto/*.h"
    base.header_mappings_dir = "Dependencies"
  end
  
end
