include(${CMAKE_CURRENT_LIST_DIR}/../common/Common.cmake)

target_include_directories(LuaSTG PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}
)
set(_custom_src
    ${CMAKE_CURRENT_LIST_DIR}/Config.h
)
source_group(TREE ${CMAKE_CURRENT_LIST_DIR} PREFIX res FILES ${_custom_src})
target_sources(LuaSTG PRIVATE
    ${_custom_src}
)
