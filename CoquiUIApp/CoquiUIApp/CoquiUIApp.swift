import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct CoquiUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = TTSViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .defaultSize(width: 800, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("TTS") {
                Button("Start Server") {
                    Task { await viewModel.startServer() }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Button("Stop Server") {
                    viewModel.stopServer()
                }
                .keyboardShortcut("q", modifiers: [.command, .shift])

                Divider()

                Button("Refresh Models") {
                    Task { await viewModel.loadModels() }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
}
