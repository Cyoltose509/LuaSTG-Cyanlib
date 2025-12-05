# 多个配置之间共享的内容

target_include_directories(LuaSTG PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}
)
set(_custom_common_src
    # 专用代码
    ${CMAKE_CURRENT_LIST_DIR}/AppFrameLuaEx.cpp
    ${CMAKE_CURRENT_LIST_DIR}/ResourcePassword.cpp
    # 专用 exe 资源文件
    ${CMAKE_CURRENT_LIST_DIR}/app.ico
    ${CMAKE_CURRENT_LIST_DIR}/resource.h
    ${CMAKE_CURRENT_LIST_DIR}/resource.rc
)
source_group(TREE ${CMAKE_CURRENT_LIST_DIR} PREFIX res FILES ${_custom_common_src})
target_sources(LuaSTG PRIVATE
    ${_custom_common_src}
)
