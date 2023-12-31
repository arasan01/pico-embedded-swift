cmake_minimum_required(VERSION 3.28)

# Without this poliy, Sourcekit-LSP won't work
if(DEFINED ENV{BUILD_FOR_IDE})
    if(POLICY CMP0126)
    cmake_policy(SET CMP0126 NEW)
    endif()
    if(POLICY CMP0157)
    cmake_policy(SET CMP0157 NEW)
    endif()
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/")

# User configuration
# Change these values to match your config.
# 
# 1) Path to Raspberry Pi Pico C/C++ SDK
#    This assumes SDK is cloned to the pico-sdk directory in your home directory.
#    Alternatively, you can set PICO_SDK_PATH as an environment variable in your shell.
if (NOT (DEFINED ENV{PICO_SDK_PATH}) AND (NOT PICO_SDK_PATH))
    set(PICO_SDK_PATH "~/pico-sdk")
    message("PICO_SDK_PATH is not set in environment, using value from CMakeLists.txt ('${PICO_SDK_PATH}')")
endif ()
# 2) Swift toolchain 
#    Change this to the current Swift nightly toolchain you installed.
#    The ID is in /Library/Developer/Toolchains/[TOOLCHAIN].xctoolchain/Info.plist
#    Alternatively, set the TOOLCHAINS environment variable.
if (NOT (DEFINED ENV{TOOLCHAINS}))
    set(Swift_Toolchain "org.swift.59202312071a")
    message("Swift toolchain: ('${Swift_Toolchain}') (using value from CMakeLists.txt as TOOLCHAINS is not set in environment)")
else ()
    set(Swift_Toolchain "$ENV{TOOLCHAINS}")
    message("Swift toolchain: ('${Swift_Toolchain}') (using TOOLCHAINS value from environment)")
endif ()

# initialize the SDK based on PICO_SDK_PATH
# note: this must happen before project()
include(pico_sdk_import.cmake)

# Configure Swift. This must happen before `project()`. I don't know why.
# Use nightly Swift compiler, configured for Embedded Swift.
# Find path to swiftc and store it in swiftc_Path
execute_process(
    COMMAND xcrun --toolchain "${Swift_Toolchain}" --find swiftc
    OUTPUT_VARIABLE swiftc_Path
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
set(CMAKE_Swift_COMPILER
    "${swiftc_Path}"
)
set(CMAKE_Swift_FLAGS
    # -wmo: Whole-module optimization is always required for Embedded Swift.
    # -Xfrontend -function-sections: enables dead stripping of unused runtime functions.
    "-target armv6m-none-none-eabi \
    -enable-experimental-feature Embedded \
    -enable-experimental-feature TypedThrows \
    -wmo \
    -Xfrontend -function-sections"
)
# Disable CMake’s automatic Swift compiler check. The compiler check always 
# fails for Embedded Swift because it tries to compile a Swift program that 
# includes `print()`, which isn't available in Embedded Swift.
set(CMAKE_Swift_COMPILER_FORCED TRUE)

project(SwiftPico LANGUAGES C CXX ASM Swift)

# Initialize the Raspberry Pi Pico SDK
pico_sdk_init()

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

if (PICO_SDK_VERSION_STRING VERSION_LESS "1.3.0")
    message(FATAL_ERROR "Raspberry Pi Pico SDK version 1.3.0 (or later) required. Your version is ${PICO_SDK_VERSION_STRING}")
endif()

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/picowi/lib
)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/picowi/lib)

add_library(SwiftLib
    SwiftLib.swift
    SwiftPicoPrint.swift
)

# set_property(TARGET SwiftLib PROPERTY Swift_COMPILATION_MODE "$<IF:$<CONFIG:Release>,wholemodule,incremental>")

add_dependencies(SwiftLib picowi)
add_dependencies(SwiftLib pico_stdlib)
add_dependencies(SwiftLib hardware_pio)
add_dependencies(SwiftLib hardware_dma)

add_executable(SwiftPico
    main.c
)

target_link_libraries(SwiftPico
    $<TARGET_OBJECTS:SwiftLib>
    pico_stdlib
    picowi hardware_pio hardware_dma
)

# Enable USB output, disable UART output
pico_enable_stdio_usb(SwiftPico 1)
pico_enable_stdio_uart(SwiftPico 0)

# create map/bin/hex file etc.
pico_add_extra_outputs(SwiftPico)