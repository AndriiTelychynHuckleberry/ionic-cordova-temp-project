package com.huckleberry_labs.amplitude;

import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.HashMap;
import java.util.Iterator;

import com.amplitude.android.Amplitude;
import com.amplitude.android.Configuration;
import com.amplitude.android.DefaultTrackingOptions;
import com.amplitude.android.utilities.DefaultEventUtils;
import com.amplitude.core.events.Identify;

public class AmplitudePlugin extends CordovaPlugin {
    private Amplitude amplitudeInstance;

    @Override
    protected void pluginInitialize() {
        super.pluginInitialize();

        String apiKey = "d1570fe4bed6b33622c5f788e2e9a09a";

        // Configuration
        Configuration configuration = new Configuration(apiKey, cordova.getActivity().getApplicationContext());
        configuration.setFlushIntervalMillis(1000);
        configuration.setFlushQueueSize(10);

        // Default tracking
        DefaultTrackingOptions defaultTrackingOptions = new DefaultTrackingOptions();
        defaultTrackingOptions.setSessions(true);
        defaultTrackingOptions.setAppLifecycles(true);
        defaultTrackingOptions.setDeepLinks(true);
        configuration.setDefaultTracking(defaultTrackingOptions);

        amplitudeInstance = new Amplitude(configuration);

        triggerOnCreateEvents(defaultTrackingOptions);
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
       if ("track".equals(action)) {
            return track(args, callbackContext);
        } else if ("setUserId".equals(action)) {
            return setUserId(args, callbackContext);
        } else if ("identify".equals(action)) {
            return identify(args, callbackContext);
        }
        return false;
    }

    private boolean track(JSONArray args, CallbackContext callbackContext) {
        try {
            String eventType = args.getString(0);
            JSONObject eventPropertiesJSON = args.getJSONObject(1);

            if (eventPropertiesJSON == null) {
                amplitudeInstance.track(eventType);
                callbackContext.success("Event tracked successfully");
            } else {
                // Convert JSONObject to HashMap
                HashMap<String, Object> eventProperties = new HashMap<>();
                Iterator<String> keys = eventPropertiesJSON.keys();
                while (keys.hasNext()) {
                    String key = keys.next();
                    eventProperties.put(key, eventPropertiesJSON.get(key));
                }

                amplitudeInstance.track(eventType, eventProperties);
                callbackContext.success("Event tracked successfully");
            }

            return true;
        } catch (JSONException e) {
            callbackContext.error("Error tracking event: " + e.getMessage());
            return false;
        }
    }


    private boolean setUserId(JSONArray args, CallbackContext callbackContext) {
        try {
            String userId = args.getString(0);
            amplitudeInstance.setUserId(userId);
            callbackContext.success("User ID set successfully");
            return true;
        } catch (JSONException e) {
            callbackContext.error("Error setting user ID: " + e.getMessage());
            return false;
        }
    }

    private boolean identify(JSONArray args, CallbackContext callbackContext) {
        try {
            String propertyName = args.getString(0);
            Object value = args.get(1); // Get the value without assuming its type
            String operation = args.getString(2);

            Identify identify = new Identify();
            switch (operation) {
                case "set":
                    if (value instanceof JSONArray) {
                        // Handle the case where value is a JSONArray
                        JSONArray valuesArray = (JSONArray) value;
                        identify.set(propertyName, valuesArray);
                    } else if (value instanceof String) {
                        // Handle the case where value is a String
                        identify.set(propertyName, (String) value);
                    } else if (value instanceof Number) {
                        // Handle the case where value is a Number
                        identify.set(propertyName, (Number) value);
                    } else {
                        callbackContext.error("Invalid value type for 'set' operation.");
                        return false;
                    }
                    break;
                case "append":
                if (value instanceof String) {
                        // Handle the case where value is a String
                        identify.append(propertyName, (String) value);
                    } else if (value instanceof Integer) {
                        // Handle the case where value is a Integer (Number type is not supported)
                        identify.append(propertyName, (int) value);
                    } else if (value instanceof Float) {
                    // Handle the case where value is a Float (Number type is not supported)
                    identify.append(propertyName, (float) value);
                } else {
                        callbackContext.error("Invalid value type for 'append' operation.");
                        return false;
                    }
                    break;
                // Add other cases for append, remove, etc. as required
                default:
                    callbackContext.error("Unsupported operation: " + operation);
                    return false;
            }

            amplitudeInstance.identify(identify);
            callbackContext.success("Identify operation successful");
            return true;
        } catch (JSONException e) {
            callbackContext.error("Error in identify operation: " + e.getMessage());
            return false;
        }
    }

    private void triggerOnCreateEvents(DefaultTrackingOptions defaultTrackingOptions) {
        if (!defaultTrackingOptions.getAppLifecycles()) return;

        amplitudeInstance.isBuilt().invokeOnCompletion((exception) -> {
            DefaultEventUtils utils = new DefaultEventUtils(amplitudeInstance);
            PackageManager packageManager = cordova.getActivity().getPackageManager();
            PackageInfo packageInfo = new PackageInfo();

            try {
                packageInfo = packageManager.getPackageInfo(cordova.getActivity().getPackageName(), 0);
            } catch (Exception ex) {
                System.out.println("Error occurred in getting package info. " + ex.getMessage());
            }
            
            utils.trackAppUpdatedInstalledEvent(packageInfo);
            utils.trackDeepLinkOpenedEvent(cordova.getActivity());

            return null;
        });
    }

    // ... Additional methods if needed ...
}
