import Foundation
#if canImport(AmplitudeSwift)
import AmplitudeSwift
#endif

@available(iOS 16, *)
public class AmplitudePlugin : CDVPlugin {
    var amplitude: Amplitude?;
    
    public override func pluginInitialize() {
        super.pluginInitialize()
        let settings = self.commandDelegate.settings!

        // let apiKey = settings["com.amplitude.api_key"]! as? String
        let apiKey = "d1570fe4bed6b33622c5f788e2e9a09a";
        
        amplitude = Amplitude(configuration: Configuration(apiKey: apiKey!, defaultTracking: DefaultTrackingOptions(sessions: true, appLifecycles: true)));
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
}
