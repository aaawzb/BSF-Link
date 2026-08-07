# BSF-Link · 精简版体脂秤连接软件

连接蚂蚁阿福（AFU）系列体脂秤的轻量客户端。目标很简单：打开就能称、称完立刻看到 8 项身体指标，一家人共用一台秤也不乱。

项目用 Flutter 一次开发、双端部署：**Android（手机/平板）** 与 **Windows（桌面）** 共用同一套 UI 与业务逻辑。本地优先，v1 不做云同步。

## 现在能做什么

- 蓝牙扫描附近体脂秤，自动连上名称含 `AFU` 的设备
- 实时读取体重，稳定后算出完整身体成分（BMI、体脂率、水分率、肌肉量、蛋白质率、骨量、内脏脂肪等级）
- 体脂算法移植自开源项目 `maoziban/smart-body-scale-android` 的 BIA 公式（男/女分性别计算，无阻抗时降级估算）
- Material 3 Expressive 界面，按屏幕宽度自适应（手机 / 平板 / 桌面大屏）

> 多成员家庭管理、本地历史存储、Windows 与 Android 数据互传属于后续里程碑，见文末路线图。

## 硬件与协议

- 设备：蚂蚁阿福同款体脂秤（复用其 BLE 协议）
- 传输：订阅 GATT 中的 `FFB2` 数据特征，每帧 20 字节原始报文，以魔数 `0xAC` 开头
- 报文解析与平台无关，放在 `lib/ble/afu_packet_parser.dart`，Android 和 Windows 共用

数据特征 UUID 是约定值，真机不符时改 `ScaleBleClient` 里的 `_dataCharacteristicUuid` 字符串常量即可，无需改动解析逻辑。

## 技术栈

| 关注点 | 选型 |
|--------|------|
| 框架 | Flutter 3.44+（Dart 3.10+） |
| 跨端状态 | flutter_riverpod 2.x |
| 蓝牙 | flutter_blue_plus 1.x（Android/iOS/macOS/Linux/Web；Windows 经已背书伴侣包 flutter_blue_plus_winrt 自动包含） |
| 本地存储 | drift 2.34 + drift_flutter（SQLite，M3 起接入） |
| 动态主题 | dynamic_color（Android 取系统配色，其它平台用种子色兜底） |
| 权限 | permission_handler（Android 9–11 定位 / 12+ 蓝牙） |

## 目录结构

```
lib/
  app/          主题与自适应断点（M3 Expressive + contentMaxWidth）
  ble/          蓝牙客户端 + AFU 报文解析（纯 Dart，跨端共享）
  domain/       领域模型与 BIA 算法（与 UI / 存储解耦）
  features/     按功能分屏：home（入口）、measure（测量→结果）
  main.dart     根组件，挂载 Riverpod 与动态取色
```

## 本地运行

前置：Flutter stable 最新、`flutter pub get` 能跑通。Android 需真机（Android 9+，支持 BLE），Windows 需 10/11。

```bash
flutter pub get
flutter create --platforms=android,windows .   # 补全原生壳（不碰你的 lib/）
flutter run                                    # Android 真机
flutter config --enable-windows-desktop && flutter run -d windows
```

Android 的蓝牙/定位权限与 `minSdk 28` 由 CI 在生成原生壳后自动注入；本地手动配置见 **SETUP.md**。

## 已知边界

- Windows 端 BLE 依赖 WinRT，需真机验证，未做模拟器适配
- 当前测量页用固定示例档案（身高 170 / 年龄 30 / 男），真实档案在 M3 接入
- 内脏脂肪等级以 BMI 近似分级展示，非设备真值
- 服务特征 UUID 在连接后遍历服务动态查找，不硬编服务 UUID

## 路线图

- **M3** 多成员家庭管理：档案增删、首测绑定、按体重 ±7kg 动态匹配成员；接入 drift 本地存储
- **M4** 历史与趋势查看
- **M5** Windows ↔ Android 数据同步（本地备份导入 / 局域网传输，不引入云端）

## 参考

- 协议与算法参考：[maoziban/smart-body-scale-android](https://github.com/maoziban/smart-body-scale-android)
- 工程初始化与权限细节：见仓库内 `SETUP.md`
