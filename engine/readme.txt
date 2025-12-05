这里是编译引擎所需的特有代码、配置、编译脚本。
如果你不知道这些东西怎么操作，请咨询璀境石。

获取引擎源码：
    引擎开源在 GitHub 上面：https://github.com/Legacy-LuaSTG-Engine/LuaSTG-Sub
    克隆仓库需要 Git，在 Windows 上需要下载 Git for Windows。

    Git for Windows 下载地址：https://git-scm.com

    然后执行 download_luastg.bat 脚本，这一步最好挂个梯子并配置好全局代理。
    顺利的话这个文件夹下面应该会出现一个 luastg 文件夹。

编译引擎：
    要编译引擎，首先要安装 Visual Studio（目前最新是 Visual Studio 2022）。

    Visual Studio 下载地址：https://visualstudio.microsoft.com/

    此外还需要 CMake，这个工具是用来配置项目的。

    CMake 下载地址：https://cmake.org/download/
    一般选 Windows x64 Installer。

    点击 build_release.bat 命令行脚本，会自动开始编译引擎。
