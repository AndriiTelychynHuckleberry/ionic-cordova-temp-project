const exec = require('cordova/exec');
const PLUGIN_NAME = "AmplitudePlugin";

var AmplitudePlugin = function () { };

AmplitudePlugin.setUserId = function (params, onSuccess = () => {}, onError = () => {}) {
  const { userId } = params;
  exec(onSuccess, onError, PLUGIN_NAME, "setUserId", [userId]);
};
AmplitudePlugin.track = function (event, onSuccess = () => {}, onError = () => {}) {
  const { prop_name, params } = event;
  exec(onSuccess, onError, PLUGIN_NAME, "track", [prop_name, params]);
};
AmplitudePlugin.identify = function (event, onSuccess = () => {}, onError = () => {}) {
  const { property_name, value, operation } = event;
  exec(onSuccess, onError, PLUGIN_NAME, "identify", [property_name, value, operation]);
};

module.exports = AmplitudePlugin;
