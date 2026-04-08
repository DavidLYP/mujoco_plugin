# 入门

## 先决条件

- 虚幻引擎 5.4+
- Windows 10/11
- Python 3.11+ (可选，用于外部策略控制)

## 安装

1. 将代码库克隆到你的虚幻引擎项目 `Plugins/` 目录中：
   ```bash
   cd "YourProject/Plugins"
   git clone https://github.com/URLab-Sim/UnrealRoboticsLab.git
   ```
2. 构建第三方依赖项（一次）：
   ```bash
   cd UnrealRoboticsLab/third_party
   # 运行 third_party/build_all.ps1
   ```
   Windows 的预编译二进制文件包含在 `third_party/install/`（MuJoCo、libzmq、CoACD）中。
3. 在虚幻引擎中打开你的 `.uproject` 文件 -- 插件会自动加载。
4. （可选）设置用于外部控制的 Python 桥接：
   ```bash
   cd UnrealRoboticsLab/urlab_bridge
   pip install uv
   uv sync
   ```

## 导入你的第一个机器人

### 来自 MJCF XML

1. 获取机器人 XML（例如，来自 [MuJoCo Menagerie](https://github.com/google-deepmind/mujoco_menagerie) ）。
2. 将 XML 文件拖入 Unreal 内容浏览器。导入程序会自动运行 `Scripts/clean_meshes.py` ，将网格转换为 GLB 格式（如果缺少 Python，则会优雅地回退到其他格式）。 
3. 蓝图会自动生成，其中包含所有关节、实体、执行器和传感器等组件。

### 快速转换（静态网格）

1. 在关卡中放置静态网格体对象（家具、道具等）。
2. 给每个动作者添加一个 `MjQuickConvertComponent`。
3. 设置为 **动态(Dynamic)** 表示物理碰撞，设置为 **静态(Static)** 表示固定碰撞。
4. 启用 `ComplexMeshRequired` 非凸形状（使用 CoACD 分解）。

## 场景设置

1. 在你的关卡中放置一个 `MjManager` 动作者（每个关卡一个）。 
2. 将导入的机器人蓝图放置在关卡中。
3. 点击播放（Play）——物理模拟自动开始。
4. MjSimulate 小部件将显示（如果管理器中 `bAutoCreateSimulateWidget` 已启用）。

## 控制机器人

### 从仪表盘

- 使用 MjSimulate 小部件中的执行器滑块来移动关节。
- 将控制源设置为 UI（在管理器上或每关节），以使用仪表板滑块而不是 ZMQ。 

### 来自 Python (ZMQ)

1. `cd` 进入 `urlab_bridge/`.
2. 安装：`uv sync` (或者 `pip install -e .`).
3. 运行策略：`uv run src/run_policy.py --policy unitree_12dof`
4. 或者使用图形用户界面：`uv run src/urlab_policy/policy_gui.py`
5. 选择您的关节和策略，点击开始。

### 从蓝图

```cpp
// 设置执行器控制值
MyArticulation->SetActuatorControl("left_hip", 0.5f);

// 读取关节状态
float Angle = MyArticulation->GetJointAngle("left_knee");

// 读取传感器数据
float Touch = MyArticulation->GetSensorScalar("foot_contact");
TArray<float> Force = MyArticulation->GetSensorReading("wrist_force");
```

所有的功能都是可调用的蓝图`BlueprintCallable`.

## 调式可视化

请参阅 [快捷键](guides/blueprint_reference.md#hotkeys) 了解键盘快捷键。

## 后续步骤

- [features.md](features.md) -- 完整功能参考
- [MJCF 导入](guides/mujoco_import.md) -- 导入管道详情
- [蓝图参考](guides/blueprint_reference.md) -- 所有蓝图可调用函数和快捷键
- [ZMQ 网络](guides/zmq_networking.md) -- 协议、主题和 Python 示例
- [策略桥接](guides/policy_bridge.md) -- 强化学习策略部署
- [开发者工具](guides/developer_tools.md) -- 模式跟踪、 XML 调试、构建/测试技能
