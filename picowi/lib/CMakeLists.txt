# PicoWi project, see http://iosoft.blog/picowi for details

# Set debug or release version
set (RELEASE 1)

cmake_minimum_required(VERSION 3.12)
include(${PICO_SDK_PATH}/pico_sdk_init.cmake)
pico_sdk_init()
include(${PICO_SDK_PATH}/tools/CMakeLists.txt)

# Set name of project (as PROJECT_NAME) and C/C++ standards
project(picowi C CXX ASM)
include(PicoSDKConfig.cmake)
set(CMAKE_C_STANDARD 11)

# Set to 0 for Pico-W CYW43439, 1 for Murata 1DX (CYW4343W)
# It may be necessary to reduce PIO_SPI_FREQ when using an external device
set (CHIP_4343W 0)

# Firmware file for CYW43439 or CYW4343W
if (${CHIP_4343W})
    message (STATUS "Building CYW4343W version")
    set (FW_FILE firmware/fw_4343w.c)
    add_compile_options(-DCHIP_4343W)
else ()
    message (STATUS "Building Pico-W CYW43439 version")
    set (FW_FILE firmware/fw_43439.c)
endif ()

# Enable compiler warnings
add_compile_options(-Wall)

# Use optimisation for release version
if (${RELEASE})
    add_compile_options(-O3 -DNDEBUG)
endif ()

set (PICOWI_SOURCES       picowi_pico.c  picowi_init.c
    picowi_wifi.c  picowi_ioctl.c picowi_scan.c 
    picowi_event.c picowi_join.c  picowi_pio.c
    picowi_ip.c    picowi_udp.c   picowi_dhcp.c
    picowi_dns.c   picowi_net.c   picowi_tcp.c
    picowi_web.c)

# Create picowi library
add_library(picowi ${PICOWI_SOURCES} ${FW_FILE})
pico_generate_pio_header(${PROJECT_NAME} ${CMAKE_CURRENT_LIST_DIR}/picowi_pio.pio)

target_link_libraries(picowi pico_stdlib hardware_pio hardware_dma)

# # Create 'picowi_demo' executable, using one of the sample source files
# add_executable(picowi_demo scan.c)
# target_link_libraries(picowi_demo picowi pico_stdlib hardware_pio hardware_dma)
# pico_add_extra_outputs(picowi_demo)
# pico_enable_stdio_usb(picowi_demo 1)
# pico_enable_stdio_uart(picowi_demo 0)