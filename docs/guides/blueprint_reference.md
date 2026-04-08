# 使用蓝图和 C++ 进行脚本编写

Unreal Robotics Lab 中的每个 MuJoCo 组件都是普通的虚幻引擎组件。关节是 Actor。您可以像操作其他 Actor 或组件一样与它们交互：获取引用、调用函数、绑定事件。除非您需要，否则无需直接操作 MuJoCo。

有关完整的类 API 列表，请参阅 [自动生成的 API 参考](../api/index.md) 。

---

## 获取参考

`AMjArticulation` 本质上就是一个动作者。获取引用的方式与通常相同：

**蓝图：** 获取所有类的参与者(Actor)、从命中结果进行类型转换，或存储引用变量。

**C++:**
```cpp
AAMjManager* Manager = AAMjManager::GetManager();
AMjArticulation* Robot = Manager->GetArticulation("MyRobot");
```

从管理器中，您可以按名称查找关节，或获取所有关节：

**蓝图：** **获取管理器** → **获取关节** (名称) / **获取所有关节**

**C++:**
```cpp
TArray<AMjArticulation*> All = Manager->GetAllArticulations();
```

---

## 使用组件

一旦你创建了一个关节，它的 MuJoCo 组件就只是子组件。你可以按名称或数组访问它们：

**蓝图：** **获取执行器** (名称), **获取关节** (名称), **获取传感器** (名称) — 或者对于数组 **获取执行器**, **获取关节**, **获取传感器**, **获取刚体**。你也可以直接从蓝图中的组件树拖拽组件。

**C++:**
```cpp
UMjActuator* Act = Robot->GetActuator("shoulder");
TArray<UMjJoint*> Joints = Robot->GetJoints();
UMjBody* Body = Robot->GetBodyByMjId(3);  // 按编译 ID
```

---

## 控制执行器

**蓝图：** 在关节上**设置执行器控制** (名称, 值)。 使用 Wire **获取游戏时间（以秒为单位）** → **正弦** → 将**执行器控制**设置为事件节拍，即可得到一个简单的正弦波。 

使用**获取执行器范围(Get Actuator Range)**获取 `Vector2D`（最小值，最大值）以限制范围。

**C++:**
```cpp
Robot->SetActuatorControl("shoulder", 1.57f);
FVector2D Range = Robot->GetActuatorRange("shoulder");
```

---

## 读取传感器

**蓝图：**

- **获取传感器标量(Get Sensor Scalar)** (名称) → Float — 适用于 1D 传感器 (触摸, 关节位置, 时钟)
- **Get Sensor Reading** (name) → Array of Float — for vector sensors (force, accelerometer)
- **Get Joint Angle** (name) → Float — shortcut for joint position

**C++:**
```cpp
float Touch = Robot->GetSensorScalar("fingertip_touch");
TArray<float> Force = Robot->GetSensorReading("wrist_force");
float Angle = Robot->GetJointAngle("elbow");
```

---

## Reacting to Collisions

`AMjArticulation` has an **On Collision** event dispatcher. Fires with: `SelfGeom` (UMjGeom*), `OtherGeom` (UMjGeom*), `ContactPos` (FVector).

**Blueprint:** Select the articulation reference → **Assign On Collision** → wire into your logic.

**C++:**
```cpp
Robot->OnCollision.AddDynamic(this, &AMyActor::HandleCollision);

void AMyActor::HandleCollision(UMjGeom* SelfGeom, UMjGeom* OtherGeom, FVector ContactPos)
{
    // Stop gripper, play effect, etc.
}
```

---

## Simulation Lifecycle

All on the manager:

| Node | What it does |
|------|-------------|
| **Set Paused** (bool) | Pause/resume the physics thread |
| **Reset Simulation** | Zero positions, velocities, time |
| **Step Sync** (N) | Advance N steps synchronously (RL-style loops) |
| **Get Sim Time** | Current simulation clock |

**C++:**
```cpp
Manager->SetPaused(true);
Manager->StepSync(10);
Manager->ResetSimulation();
float Time = Manager->GetSimTime();
```

---

## Snapshots

Save and restore the full simulation state:

**Blueprint:** **Capture Snapshot** → store in a variable → **Restore Snapshot** later.

**C++:**
```cpp
UMjSimulationState* Snap = Manager->CaptureSnapshot();
// ... try something ...
Manager->RestoreSnapshot(Snap);
```

Hold multiple snapshots for A/B testing, checkpointing, or undo.

---

## Keyframe API

On `AMjArticulation`:

| Node | What it does |
|------|-------------|
| `ResetToKeyframe(Name)` | Teleports to a named keyframe (sets qpos/qvel/ctrl) |
| `HoldKeyframe(Name)` | Continuously maintains a keyframe pose |
| `StopHoldKeyframe()` | Releases the held keyframe |
| `GetKeyframeNames()` | Returns names of all keyframes on this articulation |
| `IsHoldingKeyframe()` | Returns true if currently holding a pose |

The MjSimulate widget provides a keyframe dropdown and Reset/Hold/Stop buttons for interactive use.

---

## Recording and Replay

With an `AMjReplayManager` in the level:

**Blueprint:** **Start Recording** / **Stop Recording** / **Start Replay** / **Stop Replay** / **Save Recording to File** / **Load Recording from File**

**C++:**
```cpp
Replay->StartRecording();
// ... simulation runs ...
Replay->StopRecording();
Replay->SaveRecordingToFile("C:/data/experiment.dat");
Replay->StartReplay();
```

---

## Switching Control Source

Toggle between dashboard and external ZMQ control:

**Blueprint:** **Get Manager** → **Set Control Source** → `UI` or `ZMQ`

**C++:**
```cpp
Manager->SetControlSource(EControlSource::ZMQ);
```

Per-articulation override available on `AMjArticulation::ControlSource`.

---

## MjKeyframeController

Cycles through named poses on an articulation with ease-in-out blending.

| Node | Description |
|------|-------------|
| **LoadPreset** (name) | Load a built-in pose sequence |
| **Play** / **Stop** | Start or pause playback |
| **GoToKeyframe** (index) | Jump to a specific keyframe |
| **GetPresetNames** | Returns all available preset names |

For full details on the keyframe controller, presets, and FMjKeyframePose struct, see [Controller Framework](controller_framework.md).

---

## MjKeyframeCameraActor

`AMjKeyframeCameraActor` is a cinematic camera that smoothly interpolates through a list of waypoints (`FMjCameraWaypoint`: Position, Rotation, Time). It uses a `UCineCameraComponent` and displays a spline preview of the path in the editor.

**Key functions:**

| Node | Description |
|------|-------------|
| **Play** | Start waypoint playback |
| **Pause** | Freeze at current position |
| **TogglePlayPause** | Toggle (also bound to **O** key) |
| **Reset** | Return to first waypoint |
| **CaptureCurrentView** | (Editor only) Snapshot the viewport camera as a new waypoint |

**Properties:** `bAutoPlay`, `bAutoActivate` (sets as player view target), `bLoop`, `StartDelay`, `bSmoothInterp` (cubic vs linear).

---

## MjImpulseLauncher

`AMjImpulseLauncher` applies a velocity-based impulse to an `MjBody`. Two modes:

- **Direct** — launches along the actor's forward vector (or `DirectionOverride`).
- **Targeted** — set `LaunchTarget` to an actor and it computes a ballistic arc toward it. `ArcHeight` controls the lob.

| Node | Description |
|------|-------------|
| **FireImpulse** | Apply the impulse once |
| **ResetAndFire** | Teleport projectile back to launcher position and fire (also bound to **F** key) |

**Properties:** `TargetActor`, `TargetBodyName` (optional, defaults to first MjBody), `LaunchSpeed` (m/s), `LaunchTarget`, `ArcHeight`, `bAutoFire`, `AutoFireDelay`.

---

## Hotkeys

Handled by `AAMjManager::Tick`. Active during PIE:

| Key | Action |
|-----|--------|
| **1** | Toggle debug contacts |
| **2** | Toggle visual meshes |
| **3** | Toggle articulation collision wireframes |
| **4** | Toggle debug joints |
| **5** | Toggle quick-convert collision wireframes |
| **P** | Pause / resume simulation |
| **R** | Reset simulation |
| **O** | Toggle orbit camera orbit + keyframe camera play/pause |
| **F** | Reset and fire all impulse launchers |

---

## Per-Articulation Control Source

Each `AMjArticulation` has a `ControlSource` field (`0` = ZMQ, `1` = UI) that overrides the manager-level `EControlSource` setting. This lets you run some robots from the dashboard sliders while others receive external ZMQ commands in the same scene.

**Blueprint:** Set `ControlSource` on the articulation reference in Details or via Set node.

**C++:**
```cpp
Robot->ControlSource = 1; // UI control for this robot
```

---

## Advanced: Direct MuJoCo Access

For users who need low-level access, every `UMjComponent` exposes **Get Mj ID** (compiled integer ID), **Get Mj Name** (prefixed name), and **Is Bound** (compilation status). Use these to index directly into `mjData` from C++. For most workflows, the API above is all you need.
