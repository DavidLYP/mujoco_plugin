# Unity 插件

## 介绍

[MuJoCo Unity](https://github.com/google-deepmind/mujoco/tree/main/unity) 插件允许 Unity 编辑器和运行时使用 MuJoCo 物理引擎。用户可以导入 MJCF 文件并在编辑器中编辑模型。该插件在大多数方面（资源、游戏逻辑、模拟时间）都依赖于 Unity，但使用 MuJoCo 来确定物体的运动方式，从而使设计者能够访问 MuJoCo 的完整 API。

我们还提供了一个使用 MuJoCo 的 Unity 插件的示例项目，其中包含一系列入门教程，该项目以 [独立仓库](https://github.com/Balint-H/mj-unity-tutorial) 的形式提供。


## 安装说明

The `plug-in directory <https://github.com/google-deepmind/mujoco/tree/main/unity>`__ includes a
``package.json`` file.  Unity's package manager recognizes this file and will import the plug-in's C# codebase to your
project. In addition, Unity also needs the native MuJoCo library, which can be found in the corresponding `platform
archive <https://github.com/google-deepmind/mujoco/releases>`__. If you wish to simply use the plug-in and not
develop it, you should use one of the version-specific stable commits of the repository, identified by git tags. Check
out the relevant version of the cloned repository with git (``git checkout 3.X.Y`` where X and Y specify the engine
version). Simply using the ``main`` branch of the repository may not be compatible with the most recent release binary
of MuJoCo.

On Unity version 2020.2 and later, the Package Manager will look for the native library file and copy it to the package
directory when the package is imported. Alternatively, you can manually copy the native library to the package directory
and rename it, see platform-specific instructions below. The library can also be copied into any location under your
project's Assets directory.

### MacOS

The MuJoCo app needs to be run at least once before the native library can be used, in order to register the library as
a trusted binary. Then, copy the dynamic library file from
``/Applications/MuJoCo.app/Contents/Frameworks/mujoco.framework/Versions/Current/libmujoco.3.3.8.dylib`` (it can be
found by browsing the contents of ``MuJoCo.app``) and rename it as ``mujoco.dylib``.

### Linux

Expand the ``tar.gz`` archive to ``~/.mujoco``. Then copy the dynamic library from
``~/.mujoco/mujoco-3.3.8/lib/libmujoco.so.3.3.8`` and rename it as ``libmujoco.so``.

### Windows

Expand the ``zip`` archive to a directory called ``MuJoCo`` in your user directory, and copy the file
``MuJoCo\bin\mujoco.dll``.


## 使用插件

### Importer

导入器从编辑器的资源菜单中调用：单击“Import MuJoCo Scene”，然后选择包含模型 MJCF 规范的 XML 文件。

### Context menus
_____________

- Right-clicking a geom component offers two options:

  - "Add mesh renderer" adds components to the same game object that render the geom: a standard ``MeshRenderer`` and a
    ``MjMeshFilter`` that creates a procedural mesh that is recreated when the geom shape properties change.
  - "Convert to free object" adds two new game objects: a parent with an ``MjBody`` component and a sibling with an
    ``MjFreeJoint`` component.  This allows the previously static geom to move about freely in the scene. This action
    only applies to "world" geoms -- those that do not currently have an ``MjBody`` parent.

- Right-clicking a Unity Collider offers the option to "Add a matching MuJoCo geom" to the same game object.  Note that
  this does not comprise a complete conversion of the physics -- Rigidbody, ArticulationBody and Joint configurations
  still need to be recreated manually.

### Mouse spring

When the selected game object has an ``MjBody`` component, spring forces can be applied to this body towards the mouse
cursor through a control-left-drag action in the Scene view.  The 3D position of the spring force origin is found by
projecting the mouse position on a plane defined by the camera X direction and the world Y direction.  Adding the shift
key changes the projection plane to be parallel to the world's X and Z axes.

.. _UTips:

### Unity 用户提示

- If any compilation or runtime errors are encountered, the state of the system is undefined.  Therefore, we recommend
  turning on “Error Pause” in the console window.
- In PhysX, every `Rigidbody` is a “free body”.  In contrast, MuJoCo requires explicit specification of joints for
  mobility. For convenience, we provide a context menu for “freeing” a world geom (i.e., an ``MjGeom`` component without
  any ``MjBody`` ancestor) by adding a parent ``MjBody`` and a sibling ``MjFreeJoint``.
- The plug-in doesn’t support collision detection without physical presence, so there is no built-in notion of trigger
  colliders.  The presence or absence of a contact force can be read by adding a touch sensor and reading its
  ``SensorReading`` value (which will correspond to the normal force, see `touch sensor documentation <sensor-touch>`).

.. _UDesign:

## 设计原则

该插件设计实现了 MJCF 元素与 Unity 组件之间的一一对应关系。为了使用 MuJoCo 模拟 Unity 场景（例如，当用户在编辑器中点击“Play”按钮时），该插件：

1. 扫描场景中的 GameObject 层次结构，查找 MuJoCo 组件。
2. 创建 MJCF 描述并将其传递给 MuJoCo 的编译器。
3. 通过 MuJoCo 数据结构中的相应索引，将每个组件绑定到 MuJoCo 运行时。此索引用于在模拟期间更新 Unity 的变换。

这一设计原则具有以下几个含义：

- Unity 组件的大多数字段都直接对应于 MJCF 属性。因此，用户可以参考 MuJoCo 文档了解不同值的语义详情。
- 游戏对象(GameObject)层级结构中 MuJoCo 组件的布局决定了最终 MuJoCo 模型的布局。因此，我们采用一条设计规则：**每个游戏对象最多只能有一个 MuJoCo 组件**。
- 我们依靠 Unity 进行空间配置，这需要对矢量分量进行[交换](https://en.wikipedia.org/wiki/Swizzling_(computer_graphics)>)，因为 Unity 使用以 Y 为垂直轴的左手坐标系，而 MuJoCo 使用以 Z 为垂直轴的右手坐标系。 
- Unity变换缩放会影响整个游戏对象子树的位置、方向和大小。然而，MuJoCo 不支持倾斜圆柱体和胶囊体的碰撞（倾斜球体通过椭球体图元支持）。几何体和站点的 gizmo 会忽略这种倾斜（类似于 PhysX 碰撞器），并且始终会显示物理引擎所呈现的图元形状。
- 在运行时，更改组件字段的值不会触发场景重建，因此不会立即影响物理效果。但是，新值会在下次场景重建时加载。


我们尽可能采用 Unity 的方式：重力数据取自 Unity 的物理引擎设置，模拟步长取自 Unity 时间管理器的`固定时间步长(Fixed Timestep)`。所有外观方面（例如网格、材质和纹理）均由 Unity 的资源管理器处理，RGBA 色彩规范则通过材质资源来实现。


## 实现笔记


### Importer 工作流

When the user selects an MJCF file, the importer first loads
the file in MuJoCo, saves it to a temporary location, and then processes the generated saved file.  This has several
effects:

- It validates the MJCF - we are guaranteed that the saved MJCF matches the :ref:`schema <CSchema>`.
- It validates the assets (materials, meshes, textures) and imports these assets into Unity, as well as creating new
  material assets for geom RGBA specification.
- It allows the importer to handle :ref:`\<include\> <include>` elements without replicating MuJoCo’s file-system
  workflow.

In Unity, there is no equivalent to MJCF’s “cascading” :ref:`\<default\> <default>` clauses.  Therefore, components in
Unity reflect the corresponding elements’ state after applying all the relevant default classes, and the class structure
in the original MJCF is discarded.

### MuJoCo 场景

When a MuJoCo scene is created, the ``MjScene`` component first scans the scene for all instances of ``MjComponent``.
Each component creates its own MJCF element using Unity scene’s spatial structure to describe the model’s initial
reference pose (called ``qpos0`` in MuJoCo).  ``MjScene`` combines these XML elements according to the hierarchy of the
respective game objects and creates a single MJCF description of the physics model. It then creates the runtime structs
``mjModel`` and ``mjData``, and binds each component to the runtime by identifying its unique index.

During runtime, ``MjScene.FixedUpdate()`` calls :ref:`mj_step`, and then synchronizes the state of each game object
according to the index ``MjComponent.MujocoId`` identified at binding time.  An ``MjScene`` component is added
automatically when the application starts (e.g., when the user hits “play”) if and only if the scene includes any MuJoCo
components. If your application’s initialization phase involves ticking the physics while adding game objects and
components, you can call ``MjScene.CreateScene()`` when the initialization phase is over.

Scene recreation maintains continuity of physics and state in the following way:

1. The position and velocity of joints are cached.
2. MuJoCo’s state is reset (to ``qpos0``) and Unity transforms are synchronized.
3. A new XML is generated, creating a model that has the same ``qpos0`` as the previous one for the joints that
   persisted.
4. The MuJoCo state (for the joints that persisted) is set from the cache, and Unity transforms are synchronized.

MuJoCo has functionality for dynamic scene editing (through :ref:`mjSpec`), however, this is not yet
supported in the Unity plugin. Therefore, adding and removing MuJoCo components causes complete scene recreation.  This
can be expensive for large models or if it happens frequently.  We intend to lift this performance limitation to be in a
future versions of the plugin.

### 全局设置

An exception to the one-element-per-one-component is the Global Settings component.  This component is responsible for
all the configuration options that are included in the fixed-size, singleton, global elements of MJCF.  Currently it
holds information that corresponds to the :ref:`\<option\> <option>` and :ref:`\<size\> <size>` elements, and in the
future it will also be used for the :ref:`\<compiler\> <compiler>` element, if/when fields there will be relevant to the
Unity plug-in.

### 在应用程序运行时调用导入器 importer 

The importer is implemented by the class ``MjImporterWithAssets``, which is a subclass of ``MjcfImporter``.  This parent
class takes an MJCF string and generates the hierarchy of components.  It can be invoked at play-time (it doesn’t
involve Editor functionality), and it doesn’t invoke any functions of the MuJoCo library.  This is useful when MuJoCo
models are generated procedurally (e.g., by some evolutionary process) and/or when an MJCF is imported only to be
converted (e.g., to PhysX, or URDF).  Since it cannot interact with Unity’s ``AssetManager`` (which is a feature of the
Editor), this class’s functionality is restricted.  Specifically:

- It ignores all assets (including collision meshes).
- It ignores visuals (including RGBA specifications).

## MuJoCo 传感器组件

MuJoCo defines many sensors, and we were concerned that creating a separate ``MjComponent`` class for each would lead to
a lot of code duplication.  Therefore, we created classes according to the type of object (actuator / body / geom /
joint / site) whose properties are measured, and the type (scalar / vector / quaternion) of the measured data.

Here’s a table that maps types to sensors:

+------------------------+---------------+---------------------+
| **Mujoco Object Type** | **Data Type** | **Sensor Name**     |
+------------------------+---------------+---------------------+
| Actuator               | Scalar        | - ``actuatorpos``   |
|                        |               | - ``actuatorvel``   |
|                        |               | - ``actuatorfrc``   |
+------------------------+---------------+---------------------+
| Body                   | Vector        | - ``subtreecom``    |
|                        |               | - ``subtreelinvel`` |
|                        |               | - ``subtreeangmom`` |
|                        |               | - ``framepos``      |
|                        |               | - ``framexaxis``    |
|                        |               | - ``frameyaxis``    |
|                        |               | - ``framezaxis``    |
|                        |               | - ``framelinvel``   |
|                        |               | - ``frameangvel``   |
|                        |               | - ``framelinacc``   |
|                        |               | - ``frameangacc``   |
+------------------------+---------------+---------------------+
| Body                   | Quaternion    | - ``framequat``     |
+------------------------+---------------+---------------------+
| Geom                   | Vector        | - ``framepos``      |
|                        |               | - ``framexaxis``    |
|                        |               | - ``frameyaxis``    |
|                        |               | - ``framezaxis``    |
|                        |               | - ``framelinvel``   |
|                        |               | - ``frameangvel``   |
|                        |               | - ``framelinacc``   |
|                        |               | - ``frameangacc``   |
+------------------------+---------------+---------------------+
| Geom                   | Quaternion    | - ``framequat``     |
+------------------------+---------------+---------------------+
| Joint                  | Scalar        | - ``jointpos``      |
|                        |               | - ``jointvel``      |
|                        |               | - ``jointlimitpos`` |
|                        |               | - ``jointlimitvel`` |
|                        |               | - ``jointlimitfrc`` |
+------------------------+---------------+---------------------+
| Site                   | Scalar        | - ``touch``         |
|                        |               | - ``rangefinder``   |
+------------------------+---------------+---------------------+
| Site                   | Vector        | - ``accelerometer`` |
|                        |               | - ``velocimeter``   |
|                        |               | - ``force``         |
|                        |               | - ``torque``        |
|                        |               | - ``gyro``          |
|                        |               | - ``magnetometer``  |
|                        |               | - ``framepos``      |
|                        |               | - ``framexaxis``    |
|                        |               | - ``frameyaxis``    |
|                        |               | - ``framezaxis``    |
|                        |               | - ``framelinvel``   |
|                        |               | - ``frameangvel``   |
|                        |               | - ``framelinacc``   |
|                        |               | - ``frameangacc``   |
+------------------------+---------------+---------------------+
| Site                   | Quaternion    | - ``framequat``     |
+------------------------+---------------+---------------------+

Here’s the same table in reverse, mapping sensors to classes:

================= ===================================
Sensor Name       Plugin Class
================= ===================================
``accelerometer`` SiteVector
``actuatorfrc``   ActuatorScalar
``actuatorpos``   ActuatorScalar
``actuatorvel``   ActuatorScalar
``force``         SiteVector
``frameangacc``   \*Vector (depends on frame type)
``frameangvel``   \*Vector (depends on frame type)
``framelinacc``   \*Vector (depends on frame type)
``framelinvel``   \*Vector (depends on frame type)
``framepos``      \*Vector (depends on frame type)
``framequat``     \*Quaternion (depends on frame type)
``framexaxis``    \*Vector (depends on frame type)
``frameyaxis``    \*Vector (depends on frame type)
``framezaxis``    \*Vector (depends on frame type)
``gyro``          SiteVector
``jointlimitfrc`` JointScalar
``jointlimitpos`` JointScalar
``jointlimitvel`` JointScalar
``jointpos``      JointScalar
``jointvel``      JointScalar
``magnetometer``  SiteVector
``subtreeangmom`` BodyVector
``subtreecom``    BodyVector
``subtreelinvel`` BodyVector
``torque``        SiteVector
``touch``         SiteScalar
``velocimeter``   SiteVector
================= ===================================

The following sensors are not yet implemented:

| ``tendonpos``
| ``tendonvel``
| ``ballquat``
| ``ballangvel``
| ``tendonlimitpos``
| ``tendonlimitvel``
| ``tendonlimitfrc``
| ``user``

### 网格形状

The plug-in allows using arbitrary Unity meshes for MuJoCo collision.  At model compilation, MuJoCo calls `qhull
<http://www.qhull.org/>`__ to create a convex hull of the mesh, and uses that for collisions.  Currently the computed
convex hull is not visible in Unity, but we intend to expose it in future versions.

### Height fields


MuJoCo 的 hfield 在 Unity 中通过地形游戏对象表示。这使得可以使用 Unity 中提供的地形编辑工具来生成与 MuJoCo 碰撞的形状。在 Unity 的几何体组件中选择 hfield 类型后，右键单击上下文菜单会提供将相应的 Unity 地形添加到场景中的实用工具。地形数据会与模拟动态同步。

## MuJoCo 插件

当前版本的 Unity 软件包不支持加载使用 [MuJoCo 插件](https://mujoco.readthedocs.io/en/latest/programming/extension.html#explugin)（例如 [elasticity](https://github.com/google-deepmind/mujoco/tree/main/plugin/elasticity#readme) ）的 MJCF 场景。添加此功能将在即将发布的版本中添加。


## 和外部进程的交互

Roboti 的 [MuJoCo Unity 插件](https://roboti.us/download.html)在外部 Python 进程中执行仿真，Unity 仅用于渲染。相比之下，我们的插件则依赖 Unity 来执行仿真。因此，我们可以让外部进程“驱动”仿真，例如通过设置 qpos、调用 `mj_kinematics`、同步变换，然后使用 Unity 进行渲染或计算游戏逻辑。要与外部进程建立通信，您可以使用 Unity 的 [ML-Agents](https://github.com/Unity-Technologies/ml-agents) 包。


## 参考

* [Unity Plug-in](https://mujoco.readthedocs.io/en/latest/unity.html)

