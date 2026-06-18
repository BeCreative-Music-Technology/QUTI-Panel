cmake_minimum_required(VERSION 3.16)

project(QUTI_interface VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network)
find_package(Qt6 REQUIRED COMPONENTS QuickControls2)

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(appQUTI_interface
    main.cpp
    bridge/interface_bridge.cpp
)

qt_add_qml_module(appQUTI_interface
    URI QUTI_interface
    VERSION 1.0
    QML_FILES
        Main.qml
        qml/Module_base.qml
        qml/Control_input.qml
        modules/ModuleRegistry.qml
        modules/GainModule.qml
        modules/DelayModule.qml
    SOURCES
        bridge/interface_bridge.h
        bridge/interface_bridge.cpp
    RESOURCES
        assets/input.svg
        assets/output.svg
        QML_FILES Effects_panel.qml
        QML_FILES qml/Bus_panel.qml
        QML_FILES modules/LowPassFilterModule.qml
        QML_FILES modules/ReverbModule.qml
)


target_link_libraries(appQUTI_interface
    PRIVATE Qt6::Quick Qt6::Network
)
target_link_libraries(appQUTI_interface PRIVATE Qt6::QuickControls2)

# Optional: Windows/macOS bundle settings
set_target_properties(appQUTI_interface PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
)

install(TARGETS appQUTI_interface
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)