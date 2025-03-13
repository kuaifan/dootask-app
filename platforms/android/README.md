## Android 运行项目

确保您已经安装完成 [Android 所需环境](https://eeui.app/guide/env.html#%E5%BC%80%E5%8F%91-android)。

1.打开`AndroidStudio`软件然后`Open`Android工程目录`eeuiApp`。
2.待项目构建完成，点击 AndroidStudio 上方工具栏的 `Run`，即可运行项目。

> 第一次打开 AndroidStuido 时，由于本地环境未配置好，AndroidStuido 会提示错误，按照 IDE 提示，点击 `sync` 同步一下，大部分环境问题都可以解决。

注：

* 可能您第一次构建的时间太长您也可以尝试[解决 Android Studio 第一次导入项目太慢](https://www.jianshu.com/p/ba8189146a6b)。实在不行就请耐心等待 Android Studio 自己构建完成吧

## Android studio 配置

- 设置 JDK: `Settings > Build, Execution, Deployment > Build Tools > Gradle > Gradle JDK > 选择：corretto-11 (Amazon Corretto 11.xx)`

- 设置 NDK: `Settings > Languages & Frameworks > Android SDK > SDK Tools > 勾选 Show Package Details > 勾选 NDK (21.4.xx) > Apply`

- 设置 CMake: `Settings > Languages & Frameworks > Android SDK > SDK Tools > 勾选 Show Package Details > 勾选 CMake (3.10.2.xx) > Apply`

- 然后 `Sync Now`
