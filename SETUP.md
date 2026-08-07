# 运行与部署说明（M0 + M1 脚手架）

> 本环境未安装 Flutter，以下代码为脚手架，请在本地 Flutter 环境中完成初始化与验证。

## 1. 前置条件
- Flutter SDK ≥ 3.24（Dart ≥ 3.10，匹配 drift 2.34 线要求），推荐 stable 最新
- Android Studio / VS Code + 真机（Android 9+，支持 BLE）
- Windows 10/11（桌面端，可选）

## 2. 初始化工程
在项目根目录执行（会生成 android/、windows/、ios/ 等原生壳）：

```bash
flutter pub get
flutter create --platforms=android,windows .
```

> 若已存在 `pubspec.yaml`，`flutter create` 会补全缺失的原生平台目录，不会覆盖你的 `lib/`。

## 3. Android 权限配置
> CI 已自动注入：每次 `flutter create` 生成原生壳后，CI 会用脚本把蓝牙/定位权限写入 `AndroidManifest.xml` 并把 `minSdk` 设为 `28`（Android 9）。本地开发请手动照做（见下）。

编辑 `android/app/src/main/AndroidManifest.xml`，在 `<manifest ...>` 标签补 `xmlns:tools="http://schemas.android.com/tools"`，并在 `<application` 前加入：

```xml
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<!-- Android 12 以下扫描必须定位权限 -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
    android:maxSdkVersion="30" />
```

并将 `android/app/build.gradle.kts` 中：
- `compileSdk` 设为 `35`（reactive_ble 等依赖要求 ≥34）
- `minSdk` 设为 `28`（Android 9）

## 4. 运行
```bash
# Android 真机
flutter run

# Windows 桌面（BLE 经已背书伴侣包 flutter_blue_plus_winrt 自动提供，需真机验证）
flutter config --enable-windows-desktop
flutter run -d windows
```

## 5. 已知待办（下一阶段）
- **M2（已完成）**：`lib/domain/body_algorithm.dart` 已精确移植开源项目 BIA 算法（男/女双分支、阻抗>0 用 BIA、否则降级估算）。
- **M3**：多成员家庭管理（档案增删、首测绑定、±7kg 动态匹配）+ drift 本地存储。
- **M5**：Windows ↔ Android 数据同步机制确认（本地备份导入 / 局域网传输，不引入云端）。
- 服务特征 UUID `0000ffb2` 为常见约定值；若真机特征 UUID 不同，调整 `ScaleBleClient._dataCharacteristicUuid`（字符串常量，便于稳定比较）。
