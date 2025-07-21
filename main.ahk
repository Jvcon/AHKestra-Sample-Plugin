#Requires AutoHotkey v2.0

class Plugin {
    __New(context) {
        this.context := context
        this.apiKey := ""
    }

    Init() {
        ; --- Config Service 配置更新事件处理 ---
        EventService.On("Config.Changed", this.OnConfigChanged.Bind(this))
        this.OnConfigChanged()
        
        ; --- Text Engine Manager 热字符串高级功能 ---
        Hotkey("^!f", this.toggleFocusMode.Bind(this))
        XHotstring.HotIf(this.isFocusModeActive.Bind(this))
        XHotstring(":zen:", "Breathing in... Breathing out...")
        ; 恢复 HotIf，以免影响其他插件或 YAML 中的热字符串
        XHotstring.HotIf()
    }

    ; --- 回调函数 ---
    showSimpleMessage(ctx) {
        MsgBox("Hello from " . this.context.name . "! API Key: " . this.apiKey)
    }

    openTerminal(ctx) {
        Run "wt.exe", ctx.ActiveWindow.title
    }

    findProject(ctx) {
        MsgBox("Finding project...")
    }

    showContextInfo(ctx) {
        MsgBox("Active Window: " . ctx.ActiveWindow.title)
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

    ; --- Text Engine Manager 热字符串高级功能 ---
    toggleFocusMode(*) {
        this.isFocusMode := !this.isFocusMode
        MsgBox "SuperWriter 专注模式: " . (this.isFocusMode ? "开启" : "关闭")
    }

    isFocusModeActive(hs) {
        return this.isFocusMode
    }

    ; --- Config Service 配置与事件处理 ---
    OnConfigChanged() {
        this.apiKey := ConfigService.Get(this.context.name . ".settings.apiKey")
    }

    ; --- Condition Service 自定义条件 ---
    isExplorer(ctx) {
        return ctx.ActiveWindow.processName == "explorer.exe"
    }

}