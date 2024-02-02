import Foundation
#if canImport(AmplitudeSwift)
import AmplitudeSwift
#endif

@available(iOS 16, *)
public class AmplitudePlugin : CDVPlugin {
    var amplitude: Amplitude?;

    struct Constants {
        static let AMP_AMPLITUDE_PREFIX = "[Amplitude] "
        static let AMP_APPLICATION_INSTALLED_EVENT = "\(AMP_AMPLITUDE_PREFIX)Application Installed"
        static let AMP_APPLICATION_UPDATED_EVENT = "\(AMP_AMPLITUDE_PREFIX)Application Updated"
        static let AMP_APP_VERSION_PROPERTY = "\(AMP_AMPLITUDE_PREFIX)Version"
        static let AMP_APP_BUILD_PROPERTY = "\(AMP_AMPLITUDE_PREFIX)Build"
        static let AMP_APP_PREVIOUS_VERSION_PROPERTY = "\(AMP_AMPLITUDE_PREFIX)Previous Version"
        static let AMP_APP_PREVIOUS_BUILD_PROPERTY = "\(AMP_AMPLITUDE_PREFIX)Previous Build"
    }
    
    public override func pluginInitialize() {
        super.pluginInitialize()
        let settings = self.commandDelegate.settings!

        // let apiKey = settings["com.amplitude.api_key"]! as? String
        let apiKey = "d1570fe4bed6b33622c5f788e2e9a09a";
        
        amplitude = Amplitude(configuration: Configuration(apiKey: apiKey, defaultTracking: DefaultTrackingOptions(sessions: true, appLifecycles: true)));

        triggerOnCreateEvents();
    }
    
    @objc(track:)
    func track(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult
        guard let eventType = command.argument(at: 0) as? String,
              var eventProperties = command.argument(at: 1) as? [String: Any] else {
            pluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR, messageAs: "Invalid arguments for tracking event.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        amplitude?.track(eventType: eventType, eventProperties: eventProperties)
        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "Event tracked successfully")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc(setUserId:)
    func setUserId(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult
        guard let userId = command.argument(at: 0) as? String
        else {
            pluginResult = CDVPluginResult.init(status: CDVCommandStatus_ERROR, messageAs: "Invalid arguments for setting user id")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        amplitude?.setUserId(userId: userId)
        pluginResult = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "User id configured.")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc(identify:)
    func identify(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult
        guard let propertyName = command.argument(at: 0) as? String,
              let value = command.argument(at: 1),
              let operation = command.argument(at: 2) as? String else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid arguments for identify.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        let identify = Identify()
        switch operation {
        case "set":
            identify.set(property: propertyName, value: value)
        case "append":
            identify.append(property: propertyName, value: value)
        default:
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Unsupported operation.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        amplitude?.identify(identify: identify)
        pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Identify operation successful.")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    private func triggerOnCreateEvents() {
        let storage = amplitude?.configuration.storageProvider;
        
        let info = Bundle.main.infoDictionary
        let currentBuild = info?["CFBundleVersion"] as? String
        let currentVersion = info?["CFBundleShortVersionString"] as? String
        let previousBuild: String? = storage?.read(key: StorageKey.APP_BUILD)
        let previousVersion: String? = storage?.read(key: StorageKey.APP_VERSION)

        if self.amplitude?.configuration.defaultTracking.appLifecycles == true {
            let lastEventTime: Int64? = storage?.read(key: StorageKey.LAST_EVENT_TIME)
            if lastEventTime == nil {
                self.amplitude?.track(eventType: Constants.AMP_APPLICATION_INSTALLED_EVENT, eventProperties: [
                    Constants.AMP_APP_BUILD_PROPERTY: currentBuild ?? "",
                    Constants.AMP_APP_VERSION_PROPERTY: currentVersion ?? "",
                ])
            } else if currentBuild != previousBuild {
                self.amplitude?.track(eventType: Constants.AMP_APPLICATION_UPDATED_EVENT, eventProperties: [
                    Constants.AMP_APP_BUILD_PROPERTY: currentBuild ?? "",
                    Constants.AMP_APP_VERSION_PROPERTY: currentVersion ?? "",
                    Constants.AMP_APP_PREVIOUS_BUILD_PROPERTY: previousBuild ?? "",
                    Constants.AMP_APP_PREVIOUS_VERSION_PROPERTY: previousVersion ?? "",
                ])
            }
        }

        if currentBuild != previousBuild {
            try? storage?.write(key: StorageKey.APP_BUILD, value: currentBuild)
        }
        if currentVersion != previousVersion {
            try? storage?.write(key: StorageKey.APP_VERSION, value: currentVersion)
        }
    }
}
