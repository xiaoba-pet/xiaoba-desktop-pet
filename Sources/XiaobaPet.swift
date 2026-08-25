import AppKit
import QuartzCore

private struct HeartParticle {
    var x: CGFloat
    var y: CGFloat
    var drift: CGFloat
    var bornAt: TimeInterval
    var lifetime: TimeInterval
}

final class PetView: NSView {
    private let image: NSImage
    private var displayTimer: Timer?
    private var trackingAreaRef: NSTrackingArea?
    private var message: String?
    private var messageExpiresAt: TimeInterval = 0
    private var jumpStartedAt: TimeInterval?
    private var wobbleStartedAt: TimeInterval?
    private var hearts: [HeartParticle] = []
    private var mouseDownLocation: NSPoint?
    private var windowOriginAtMouseDown: NSPoint?
    private var didDrag = false
    private var handledDoubleClick = false
    private var hovered = false
    private var walking = false
    private var facingLeft = false
    private(set) var sleeping = false

    var onPositionChanged: (() -> Void)?
    var onResetPosition: (() -> Void)?
    var onToggleTopmost: (() -> Bool)?
    var onToggleAutoWalk: (() -> Bool)?
    var onShowAbout: (() -> Void)?
    var onQuit: (() -> Void)?

    init(frame: NSRect, image: NSImage) {
        self.image = image
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        startDisplayTimer()
    }

    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        displayTimer?.invalidate()
    }

    override var acceptsFirstResponder: Bool { true }

    override func updateTrackingAreas() {
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingAreaRef = area
        super.updateTrackingAreas()
    }

    private func startDisplayTimer() {
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        displayTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func tick() {
        let now = CACurrentMediaTime()
        if message != nil, now >= messageExpiresAt {
            message = nil
        }
        hearts.removeAll { now - $0.bornAt >= $0.lifetime }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        let now = CACurrentMediaTime()
        let phase = now * (sleeping ? 1.3 : walking ? 7.0 : 2.3)
        let bob = CGFloat(sin(phase)) * (sleeping ? 1.2 : walking ? 4.8 : 2.1)
        let breathingScale = 1 + CGFloat(sin(phase * 0.72)) * (sleeping ? 0.008 : 0.014)
        let hoverScale: CGFloat = hovered && !sleeping ? 1.035 : 1
        let jump = jumpOffset(at: now)
        let wobble = wobbleAngle(at: now)
        let baseSize: CGFloat = 218
        let center = NSPoint(x: bounds.midX, y: 112 + bob + jump)

        NSGraphicsContext.saveGraphicsState()
        if let context = NSGraphicsContext.current?.cgContext {
            context.translateBy(x: center.x, y: center.y)
            context.rotate(by: wobble)
            context.scaleBy(
                x: (facingLeft ? -1 : 1) * breathingScale * hoverScale,
                y: breathingScale * hoverScale
            )
            let petRect = NSRect(x: -baseSize / 2, y: -baseSize / 2, width: baseSize, height: baseSize)
            image.draw(
                in: petRect,
                from: .zero,
                operation: .sourceOver,
                fraction: sleeping ? 0.90 : 1,
                respectFlipped: true,
                hints: [.interpolation: NSImageInterpolation.high]
            )
        }
        NSGraphicsContext.restoreGraphicsState()

        drawHearts(now: now)
        if sleeping {
            drawSleepMarks(now: now)
        }
        if let message {
            drawBubble(message)
        }
    }

    private func jumpOffset(at now: TimeInterval) -> CGFloat {
        guard let jumpStartedAt else { return 0 }
        let progress = (now - jumpStartedAt) / 0.66
        if progress >= 1 {
            self.jumpStartedAt = nil
            return 0
        }
        return CGFloat(sin(progress * .pi)) * 38
    }

    private func wobbleAngle(at now: TimeInterval) -> CGFloat {
        guard let wobbleStartedAt else { return 0 }
        let progress = (now - wobbleStartedAt) / 0.62
        if progress >= 1 {
            self.wobbleStartedAt = nil
            return 0
        }
        return CGFloat(sin(progress * .pi * 5)) * (1 - CGFloat(progress)) * 0.10
    }

    private func drawBubble(_ text: String) {
        let font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(calibratedWhite: 0.13, alpha: 1),
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let measured = attributed.boundingRect(
            with: NSSize(width: 214, height: 80),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        ).integral
        let bubbleSize = NSSize(width: min(238, max(92, measured.width + 28)), height: measured.height + 20)
        let bubbleRect = NSRect(
            x: bounds.midX - bubbleSize.width / 2,
            y: bounds.maxY - bubbleSize.height - 8,
            width: bubbleSize.width,
            height: bubbleSize.height
        )

        let shadow = NSShadow()
        shadow.shadowBlurRadius = 12
        shadow.shadowOffset = NSSize(width: 0, height: -3)
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)

        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        NSColor.white.withAlphaComponent(0.96).setFill()
        NSBezierPath(roundedRect: bubbleRect, xRadius: 16, yRadius: 16).fill()
        NSGraphicsContext.restoreGraphicsState()

        let pointer = NSBezierPath()
        pointer.move(to: NSPoint(x: bubbleRect.midX - 8, y: bubbleRect.minY + 1))
        pointer.line(to: NSPoint(x: bubbleRect.midX + 8, y: bubbleRect.minY + 1))
        pointer.line(to: NSPoint(x: bubbleRect.midX, y: bubbleRect.minY - 10))
        pointer.close()
        NSColor.white.withAlphaComponent(0.96).setFill()
        pointer.fill()

        attributed.draw(in: NSRect(
            x: bubbleRect.minX + 14,
            y: bubbleRect.minY + 10,
            width: bubbleRect.width - 28,
            height: bubbleRect.height - 20
        ))
    }

    private func drawHearts(now: TimeInterval) {
        let font = NSFont.systemFont(ofSize: 22, weight: .bold)
        for heart in hearts {
            let progress = CGFloat((now - heart.bornAt) / heart.lifetime)
            let alpha = max(0, 1 - progress)
            let point = NSPoint(
                x: heart.x + heart.drift * progress,
                y: heart.y + progress * 76
            )
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.systemPink.withAlphaComponent(alpha),
            ]
            NSString(string: "♥").draw(at: point, withAttributes: attributes)
        }
    }

    private func drawSleepMarks(now: TimeInterval) {
        let pulse = CGFloat((sin(now * 2.2) + 1) / 2)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18 + pulse * 3, weight: .bold),
            .foregroundColor: NSColor.systemIndigo.withAlphaComponent(0.65 + pulse * 0.25),
        ]
        NSString(string: "Zzz").draw(at: NSPoint(x: 198, y: 184 + pulse * 5), withAttributes: attributes)
    }

    private func showMessage(_ text: String, duration: TimeInterval = 2.2) {
        message = text
        messageExpiresAt = CACurrentMediaTime() + duration
        needsDisplay = true
    }

    private func emitHearts(_ count: Int) {
        let now = CACurrentMediaTime()
        for index in 0..<count {
            hearts.append(HeartParticle(
                x: CGFloat.random(in: 92...182),
                y: CGFloat.random(in: 118...164),
                drift: CGFloat.random(in: -28...28),
                bornAt: now + Double(index) * 0.05,
                lifetime: Double.random(in: 0.9...1.45)
            ))
        }
    }

    func pat() {
        if sleeping {
            sleeping = false
        }
        let replies = ["嘿嘿，好舒服～", "小八最喜欢你啦！", "再摸一下嘛～", "汪！"]
        showMessage(replies.randomElement() ?? "汪！")
        wobbleStartedAt = CACurrentMediaTime()
        emitHearts(3)
    }

    func feed() {
        if sleeping {
            sleeping = false
        }
        showMessage("嗷呜！谢谢你的零食～")
        jumpStartedAt = CACurrentMediaTime()
        wobbleStartedAt = CACurrentMediaTime()
        emitHearts(7)
    }

    func callName() {
        if sleeping {
            sleeping = false
            showMessage("唔……小八醒啦！")
        } else {
            showMessage("我在呢！")
            jumpStartedAt = CACurrentMediaTime()
        }
    }

    func toggleSleep() {
        sleeping.toggle()
        walking = false
        showMessage(sleeping ? "小八先睡一会儿……" : "早上好！")
    }

    func setWalking(_ walking: Bool, facingLeft: Bool = false) {
        self.walking = walking
        self.facingLeft = walking ? facingLeft : false
        if walking, sleeping {
            sleeping = false
        }
    }

    override func mouseEntered(with event: NSEvent) {
        hovered = true
        if message == nil, !sleeping {
            showMessage("嗨～我是小八")
        }
    }

    override func mouseExited(with event: NSEvent) {
        hovered = false
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = NSEvent.mouseLocation
        windowOriginAtMouseDown = window?.frame.origin
        didDrag = false
        handledDoubleClick = event.clickCount >= 2
        if handledDoubleClick {
            toggleSleep()
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window, let startMouse = mouseDownLocation, let startOrigin = windowOriginAtMouseDown else {
            return
        }
        let current = NSEvent.mouseLocation
        let delta = NSPoint(x: current.x - startMouse.x, y: current.y - startMouse.y)
        if abs(delta.x) + abs(delta.y) > 4 {
            didDrag = true
        }
        window.setFrameOrigin(NSPoint(x: startOrigin.x + delta.x, y: startOrigin.y + delta.y))
    }

    override func mouseUp(with event: NSEvent) {
        if didDrag {
            onPositionChanged?()
        } else if !handledDoubleClick {
            pat()
        }
        mouseDownLocation = nil
        windowOriginAtMouseDown = nil
    }

    override func rightMouseDown(with event: NSEvent) {
        NSMenu.popUpContextMenu(makeContextMenu(), with: event, for: self)
    }

    private func menuItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu(title: "小八")
        menu.addItem(menuItem("摸摸小八", action: #selector(patFromMenu)))
        menu.addItem(menuItem("叫小八", action: #selector(callFromMenu)))
        menu.addItem(menuItem("给小八零食", action: #selector(feedFromMenu)))
        menu.addItem(menuItem(sleeping ? "叫醒小八" : "让小八睡觉", action: #selector(sleepFromMenu)))
        menu.addItem(.separator())
        menu.addItem(menuItem("自动散步 开/关", action: #selector(autoWalkFromMenu)))
        menu.addItem(menuItem("始终置顶 开/关", action: #selector(topmostFromMenu)))
        menu.addItem(menuItem("回到右下角", action: #selector(resetFromMenu)))
        menu.addItem(.separator())
        menu.addItem(menuItem("关于小八", action: #selector(aboutFromMenu)))
        menu.addItem(menuItem("退出小八", action: #selector(quitFromMenu)))
        return menu
    }

    @objc private func patFromMenu() { pat() }
    @objc private func callFromMenu() { callName() }
    @objc private func feedFromMenu() { feed() }
    @objc private func sleepFromMenu() { toggleSleep() }

    @objc private func autoWalkFromMenu() {
        let enabled = onToggleAutoWalk?() ?? false
        showMessage(enabled ? "散步时间到！" : "小八不乱跑啦")
    }

    @objc private func topmostFromMenu() {
        let enabled = onToggleTopmost?() ?? true
        showMessage(enabled ? "我会一直陪着你～" : "我安静待在桌面")
    }

    @objc private func resetFromMenu() { onResetPosition?() }
    @objc private func aboutFromMenu() { onShowAbout?() }
    @objc private func quitFromMenu() { onQuit?() }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let windowSize = NSSize(width: 280, height: 300)
    private let positionDefaultsKey = "XiaobaPetWindowOrigin"
    private let autoWalkDefaultsKey = "XiaobaPetAutoWalk"
    private let topmostDefaultsKey = "XiaobaPetTopmost"
    private var window: NSWindow!
    private var petView: PetView!
    private var statusItem: NSStatusItem?
    private var walkTimer: Timer?
    private var autoWalkEnabled = false
    private var topmost = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        guard let image = loadPetImage() else {
            showFatalError("找不到小八的图片资源 xiaoba.png")
            return
        }

        autoWalkEnabled = UserDefaults.standard.bool(forKey: autoWalkDefaultsKey)
        if UserDefaults.standard.object(forKey: topmostDefaultsKey) == nil {
            topmost = true
        } else {
            topmost = UserDefaults.standard.bool(forKey: topmostDefaultsKey)
        }

        buildWindow(image: image)
        buildStatusItem()
        installWalkTimer()
    }

    private func loadPetImage() -> NSImage? {
        let explicitPath = argumentValue("--image")
        let path = explicitPath ?? Bundle.main.path(forResource: "xiaoba", ofType: "png")
        guard let path else { return nil }
        return NSImage(contentsOfFile: path)
    }

    private func buildWindow(image: NSImage) {
        let savedOrigin = savedWindowOrigin()
        let initialOrigin = savedOrigin ?? defaultWindowOrigin()
        window = NSWindow(
            contentRect: NSRect(origin: initialOrigin, size: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.level = topmost ? .floating : .normal
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.animationBehavior = .utilityWindow

        petView = PetView(frame: NSRect(origin: .zero, size: windowSize), image: image)
        petView.onPositionChanged = { [weak self] in self?.saveWindowOrigin() }
        petView.onResetPosition = { [weak self] in self?.resetPosition() }
        petView.onToggleTopmost = { [weak self] in self?.toggleTopmost() ?? true }
        petView.onToggleAutoWalk = { [weak self] in self?.toggleAutoWalk() ?? false }
        petView.onShowAbout = { [weak self] in self?.showAbout() }
        petView.onQuit = { NSApp.terminate(nil) }
        window.contentView = petView
        window.makeKeyAndOrderFront(nil)
    }

    private func buildStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.title = "🐶"
        item.button?.toolTip = "小八桌面宠物"
        let menu = NSMenu(title: "小八")
        menu.addItem(statusMenuItem("叫小八", action: #selector(callPet)))
        menu.addItem(statusMenuItem("给小八零食", action: #selector(feedPet)))
        menu.addItem(statusMenuItem("睡觉 / 起床", action: #selector(toggleSleep)))
        menu.addItem(.separator())
        menu.addItem(statusMenuItem("显示小八", action: #selector(showPet)))
        menu.addItem(statusMenuItem("回到右下角", action: #selector(resetPetPosition)))
        menu.addItem(.separator())
        menu.addItem(statusMenuItem("退出小八", action: #selector(quitPet)))
        item.menu = menu
        statusItem = item
    }

    private func statusMenuItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func installWalkTimer() {
        let timer = Timer(timeInterval: 13, repeats: true) { [weak self] _ in
            self?.takeAutomaticWalkIfNeeded()
        }
        walkTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func takeAutomaticWalkIfNeeded() {
        guard autoWalkEnabled, !petView.sleeping, let screen = window.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        let oldOrigin = window.frame.origin
        let direction: CGFloat = Bool.random() ? 1 : -1
        let distance = CGFloat.random(in: 80...180) * direction
        let targetX = min(visible.maxX - window.frame.width, max(visible.minX, oldOrigin.x + distance))
        let targetY = min(visible.maxY - window.frame.height, max(visible.minY, oldOrigin.y + CGFloat.random(in: -24...24)))
        guard abs(targetX - oldOrigin.x) > 8 else { return }

        petView.setWalking(true, facingLeft: targetX < oldOrigin.x)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 1.8
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrameOrigin(NSPoint(x: targetX, y: targetY))
        } completionHandler: { [weak self] in
            self?.petView.setWalking(false)
            self?.saveWindowOrigin()
        }
    }

    private func toggleAutoWalk() -> Bool {
        autoWalkEnabled.toggle()
        UserDefaults.standard.set(autoWalkEnabled, forKey: autoWalkDefaultsKey)
        if !autoWalkEnabled {
            petView.setWalking(false)
        }
        return autoWalkEnabled
    }

    private func toggleTopmost() -> Bool {
        topmost.toggle()
        window.level = topmost ? .floating : .normal
        UserDefaults.standard.set(topmost, forKey: topmostDefaultsKey)
        return topmost
    }

    private func defaultWindowOrigin() -> NSPoint {
        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        return NSPoint(x: visible.maxX - windowSize.width - 24, y: visible.minY + 22)
    }

    private func savedWindowOrigin() -> NSPoint? {
        guard let value = UserDefaults.standard.string(forKey: positionDefaultsKey) else { return nil }
        return NSPointFromString(value)
    }

    private func saveWindowOrigin() {
        UserDefaults.standard.set(NSStringFromPoint(window.frame.origin), forKey: positionDefaultsKey)
    }

    private func resetPosition() {
        let origin = defaultWindowOrigin()
        window.setFrameOrigin(origin)
        saveWindowOrigin()
        petView.callName()
    }

    private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "小八桌面宠物"
        alert.informativeText = "单击摸摸，双击睡觉或唤醒，拖动可以搬家。右键还能喂零食、自动散步和切换置顶。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "知道啦")
        alert.runModal()
    }

    private func showFatalError(_ message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "小八启动失败"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.runModal()
        NSApp.terminate(nil)
    }

    @objc private func callPet() { petView.callName() }
    @objc private func feedPet() { petView.feed() }
    @objc private func toggleSleep() { petView.toggleSleep() }
    @objc private func showPet() { window.makeKeyAndOrderFront(nil) }
    @objc private func resetPetPosition() { resetPosition() }
    @objc private func quitPet() { NSApp.terminate(nil) }
}

private func argumentValue(_ key: String) -> String? {
    let arguments = CommandLine.arguments
    for index in arguments.indices where arguments[index] == key && index + 1 < arguments.count {
        return arguments[index + 1]
    }
    return nil
}

let app = NSApplication.shared
if let previewPath = argumentValue("--render-preview") {
    let imagePath = argumentValue("--image") ?? Bundle.main.path(forResource: "xiaoba", ofType: "png")
    guard let imagePath, let image = NSImage(contentsOfFile: imagePath) else {
        fputs("unable to load xiaoba image for preview\n", stderr)
        exit(1)
    }
    let size = NSSize(width: 280, height: 300)
    let view = PetView(frame: NSRect(origin: .zero, size: size), image: image)
    view.callName()
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width * 2),
        pixelsHigh: Int(size.height * 2),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        exit(1)
    }
    bitmap.size = size
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        exit(1)
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    view.draw(view.bounds)
    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        exit(1)
    }
    do {
        try data.write(to: URL(fileURLWithPath: previewPath))
        exit(0)
    } catch {
        fputs("preview write failed: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
}
let delegate = AppDelegate()
app.delegate = delegate
app.run()
