# AHKestra Sample Plugin 官方示例插件

欢迎来到 AHKestra 插件开发的世界！本仓库旨在为您提供一个功能完整、注释详尽的起点。通过研究本插件的代码，您将能快速掌握为 AHKestra 贡献功能所需的一切知识。

克隆此仓库后，将其放置在您 AHKestra 安装目录的 `Plugins` 文件夹下即可立即生效。

## 核心概念

AHKestra 的插件系统基于两大核心概念：
1.  **声明式贡献 (Declarative Contributions)**: 您通过 `manifest.json` 文件“声明”您的插件想为系统添加什么功能（如热键、菜单项）。
2.  **程序化实现 (Programmatic Implementation)**: 您在 `main.ahk` 中的 `Plugin` 类里编写代码，来响应用户的操作和框架的事件。

---

## 1. `manifest.json` 详解

`manifest.json` 是您插件的“身份证”和“功能说明书”。框架通过读取它来了解您的插件。

### 1.1 基础元数据

这些是每个插件都必须包含的基本信息。

```json
{
    "name": "SamplePlugin",
    "version": "1.0.0",
    "author": "Your Name",
    "description": "一个展示 AHKestra 插件开发各项能力的示例插件。"
}
```

### 1.2 `main`

指定插件的入口脚本文件。

```json
{
    "main": "main.ahk"
}
```

### 1.3 `contributes` - 贡献功能

这是 `manifest.json` 最核心的部分，您在这里声明插件向 AHKestra 系统贡献的所有功能。

#### 1.3.1 贡献热键 (`hotkeys`)

```json
"contributes": {
    "hotkeys": [
        {
            "keys": ["^!s"],
            "type": "regular",
            "function": "showSimpleMessage",
            "hint": "显示一条简单的信息"
        },
        {
            "keys": ["AppsKey", "t"],
            "type": "layer",
            "function": "openTerminal",
            "hint": "在当前目录打开终端",
            "condition": "isExplorer"
        },
        {
            "keys": ["f", "p"],
            "type": "sequence",
            "function": "findProject",
            "hint": "查找并打开项目"
        },
        {
                "keys": ["^!n"],
                "type": "regular",
                "function": "createFileAndRefresh",
                "hint": "在资源管理器中创建文件并刷新上下文",
                "condition": "isExplorer"
        }
    ]
}
```
*   `keys`: 按键定义。对于 `sequence` 类型，无需包含 `<Leader>` 键。
*   `type`: 热键类型，可以是 `regular`, `layer`, `sequence`。
*   `function`: 对应 `main.ahk` 中 `Plugin` 类里的方法名。
*   `hint`: （可选）在 `which-key` 等UI中显示的提示文本。
*   `condition`: （可选）一个条件字符串，决定此热键何时生效。可以是[内置条件](#31-内置条件库)，也可以是您在插件中[自定义的条件函数](#32-自定义条件)。

#### 1.3.2 贡献上下文菜单项 (`menuItems`)

```json
"contributes": {
    "menuItems": [
        {
            "path": "示例插件/操作/显示上下文信息",
            "function": "showContextInfo",
            "condition": "" 
        },
        {
            "path": "文件操作/在VSCode中打开",
            "function": "openInVSCode",
            "condition": "isExplorer"
        }
    ]
}
```
*   `path`: 菜单的层级路径，用 `/` 分隔。
*   `function`: 点击菜单项时调用的方法。
*   `condition`: （可选）决定此菜单项何时可见。

#### 1.3.3 贡献文本扩展 (`expansions`)

```json
"contributes": {
    "expansions": [
        "expansions/common-phrases.yml"
    ]
}
```
*   指定一个或多个相对于插件根目录的 `.yml` 文件路径。文件格式遵循 [Espanso](https://espanso.org/) 的 `matches` 语法。

### 1.4 `configuration` - 声明式配置

这是让用户可以图形化配置您插件的关键。您在这里声明插件需要的所有配置项及其规格。

```json
"configuration": {
    "apiKey": {
        "type": "string",
        "default": "",
        "label": "API Key",
        "description": "用于访问服务的秘密 API 密钥。"
    },
    "autoStart": {
        "type": "boolean",
        "default": true,
        "label": "自动启动",
        "description": "如果勾选，此插件将随 AHKestra 自动启动。"
    },
    "displayMode": {
        "type": "dropdown",
        "default": "compact",
        "label": "显示模式",
        "description": "结果的显示方式。",
        "options": [
            { "label": "紧凑视图", "value": "compact" },
            { "label": "详细视图", "value": "detailed" }
        ]
    }
}
```
*   `type`: 支持 `string`, `boolean`, `number`, `dropdown`。
*   `default`: 默认值。
*   `label`: 在设置界面中显示的标签文本。
*   `description`: （可选）鼠标悬浮在 `(?)` 图标上时显示的帮助提示。
*   `options`: （仅 `dropdown` 类型需要）下拉选项的数组。

---

## 2. `main.ahk` - 插件逻辑实现

`main.ahk` 必须包含一个名为 `Plugin` 的类。AHKestra 会在加载时自动创建这个类的实例。

### 2.1 基础结构

```autohotkey
#Requires AutoHotkey v2.0

class Plugin {
    __New(context) {
        ; 构造函数，在插件加载时调用。
        ; `context` 包含了插件的元数据，如 name, version, dir。
        this.context := context

        ; 推荐在这里进行一些属性的初始化
        this.mySetting = ""
    }

    Init() {
        ; 可选的初始化方法，在插件加载并处理完 manifest 后调用。
        ; 这里是进行程序化注册的最佳位置。
        
        ; 示例：加载配置
        this.OnConfigChanged() 
        
        ; 示例：订阅配置变更事件
        EventService.On("Config.Changed", this.OnConfigChanged.Bind(this))

        ; 示例：注册自定义的上下文提供者
        ContextService.RegisterProvider("Code.exe", this.getVSCodeContext.Bind(this))
    }
    
    ; ... 您的方法 ...
}
```

### 2.2 实现回调函数

您在 `manifest.json` 中声明的 `function` 都需要在这里作为 `Plugin` 类的方法来实现。

```autohotkey
class Plugin {
    ; ...
    
    ; 对应 hotkeys 中的 "showSimpleMessage"
    showSimpleMessage(ctx) {
        MsgBox "Hello from " . this.context.name . "!"
    }

    ; 对应 menuItems 中的 "showContextInfo"
    showContextInfo(ctx) {
        MsgBox "当前活动窗口的标题是: " . ctx.ActiveWindow.title
    }

    ; ... 其他回调 ...
}
```
*   **重要**: 所有的回调函数都会接收一个参数 `ctx`，这是由 `ContextService` 提供的、包含当前所有上下文信息的对象。

### 2.3 `ctx` 上下文对象

`ctx` 对象是 AHKestra 的核心，它包含了您做出智能判断所需的一切信息。以下是其主要结构：
*   `ctx.ActiveWindow`: Map, 包含 `hwnd`, `title`, `class`, `processPath`, `processName`。
*   `ctx.MouseTarget`: Map, 包含鼠标指针下的窗口和控件信息。
*   `ctx.FocusedControl`: Map, 包含当前焦点控件的信息。
*   `ctx.Displays`: Map, 包含所有显示器的信息。
*   `ctx.VirtualDesktop`: Map, 包含虚拟桌面信息。
*   `ctx.TextSources`: Map, 包含 `selection` (选中内容) 和 `clipboard` (剪贴板内容)。
*   `ctx.<plugin_custom_key>`: 由插件的上下文提供者注入的自定义键值对。

---

## 3. AHKestra 框架 API

您的插件可以调用由框架提供的一系列服务和方法。

### 3.1 内置条件库

`ConditionService` 提供了一系列可以直接在 `manifest.json` 中使用的通用条件。

*   `isExplorer`: 当前是否在资源管理器中。
*   `isBrowser`: 当前是否在主流浏览器中。
*   `isMaximized`: 当前窗口是否最大化。
*   `hasSelection`: 当前是否有选中的文本。
*   `hasText`: 当前是否有选中的文本或剪贴板内容。
*   `selectionIsUrl`: 选中的文本是否为URL。
*   `clipboardIsUrl`: 剪贴板内容是否为URL。

### 3.2 自定义条件

如果内置条件不满足需求，您可以在插件类中定义自己的条件函数，并在 `manifest.json` 中直接使用其方法名。

```autohotkey
; main.ahk
class Plugin {
    ; ...
    isVSCode(ctx) {
        return ctx.ActiveWindow.processName == "Code.exe"
    }
}
```

```json
; manifest.json
"menuItems": [{
    "path": "在终端中打开",
    "function": "...",
    "condition": "isVSCode"  // <-- 直接使用方法名
}]
```

### 3.3 核心服务

您可以通过全局类名直接访问以下核心服务：

*   **`ConfigService`**:
    *   `ConfigService.Get(path)`: 获取配置项，如 `this.context.name . ".settings.apiKey"`。
*   **`EventService`**:
    *   `EventService.On(event, callback)`: 订阅事件。
    *   `EventService.Trigger(event, data)`: 触发事件。
    *   **关键事件**: `"Config.Changed"`
*   **`ContextService`**:
    *   `ContextService.RegisterProvider(processName, providerFunc)`: 注册一个针对特定程序的深度上下文提供者。
    *   **`ContextService.InvalidateContext(scope)`**: **[ 新增 ]** 主动使上下文缓存失效。这是实现精细化上下文感知的**关键API**。
        *   **`scope`** (字符串，可选，默认为 `"active"`):
            *   `"active"`: 使“活动层”缓存失效。当您的插件执行了某个操作（如文件创建、目录切换、与应用内部API交互），改变了当前窗口的内部状态，但**并未切换窗口**时，您**应该**调用此方法。这能确保下一次操作获取到最新的文本选择、焦点控件或插件自定义的上下文。
            *   `"all"`: 使所有层级的缓存（包括“稳定层”）都失效。这是一种更彻底的刷新，通常在执行了可能影响整个系统状态的宏大操作后使用。
*   **`GuiService`**: 主要由框架内部使用。
*   **`PluginConfigGuiFactory`**:
    *   `this.ShowConfiguration(ownerHwnd)`: 如果您在 `manifest` 中定义了 `configuration`，框架会自动为您注入此方法，用于显示您插件的配置窗口。


---

### `main.ahk` (示例代码)

```autohotkey
#Requires AutoHotkey v2.0

class Plugin {
    __New(context) {
        this.context := context
        this.apiKey := ""
    }

    Init() {
        EventService.On("Config.Changed", this.OnConfigChanged.Bind(this))
        this.OnConfigChanged()
    }

    ; --- 回调函数 ---
    showSimpleMessage(ctx) {
        MsgBox "Hello from " . this.context.name . "! API Key: " . this.apiKey
    }
    
    openTerminal(ctx) {
        Run "wt.exe", ctx.ActiveWindow.title
    }

    findProject(ctx) {
        MsgBox "Finding project..."
    }

    showContextInfo(ctx) {
        MsgBox "Active Window: " . ctx.ActiveWindow.title
    }
    
    openInVSCode(ctx) {
        Run "code .", ctx.ActiveWindow.title
    }

    /**
     * 对应 hotkeys 中的 "createFileAndRefresh"
     * 这个函数演示了插件如何在执行一个改变内部状态的操作后，
     * 主动通知框架更新上下文缓存。
     */
    createFileAndRefresh(ctx) {
        ; 1. 从上下文中获取当前资源管理器的路径
        local currentPath := ctx.ActiveWindow.title
        
        ; 2. 执行一个会改变“活动层”上下文的操作。
        ;    例如，在当前路径下创建一个新文件。
        ;    这个操作不会切换窗口，因此无法被框架的事件钩子自动捕获。
        try {
            FileAppend("This is a new file created by AHKestra Sample Plugin.", currentPath . "\AHKestra_Test_File.txt")
            MsgBox "文件已在以下路径创建：`n" . currentPath, "操作成功", 64
        } catch {
            MsgBox "文件创建失败，请检查权限。", "错误", 16
            return
        }

        ; 3. **核心步骤**: 主动使“活动层”缓存失效。
        ;    如果不执行这一步，在缓存有效期内（如250ms）立即触发的下一个依赖
        ;    “选中文本”或“焦点控件”的热键，可能会获取到陈旧的上下文。
        ContextService.InvalidateContext("active")
        
        ; (可选) 为了演示效果，可以立即获取一次新的上下文并显示
        ; local newCtx := ContextService.GetContext()
        ; MsgBox "上下文已刷新！"
    }

    ; --- 配置与事件处理 ---
    OnConfigChanged() {
        this.apiKey := ConfigService.Get(this.context.name . ".settings.apiKey")
    }

    ; --- 自定义条件 ---
    isExplorer(ctx) {
        return ctx.ActiveWindow.processName == "explorer.exe"
    }
}
```
