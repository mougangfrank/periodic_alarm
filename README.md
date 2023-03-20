## Getting Started

### iOS installation steps

To import your alarm audio(s), you will need to drag and drop your asset(s) to your `Runner` folder in Xcode. 
I published a Gist to show you the steps to follow, and also give you a tip to save your app some weight using symbolic links. It's [right here](https://gist.github.com/gdelataillade/68834caacdd6727f1418e46788f70b53).

### Android installation steps

In your `android/app/build.gradle`, make sure you have the following config:
```Gradle
android {
  compileSdkVersion 33
  [...]
  defaultConfig {
    [...]
    multiDexEnabled true
  }
}
```

After that, add the following to your `AndroidManifest.xml` within the `<manifest></manifest>` tags:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<!-- For apps with targetSDK=31 (Android 12) -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

Next, within the `<application></application>` tags, add:

```xml
<service
    android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmService"
    android:permission="android.permission.BIND_JOB_SERVICE"
    android:exported="false"/>
<receiver
    android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmBroadcastReceiver"
    android:exported="false"/>
<receiver
    android:name="dev.fluttercommunity.plus.androidalarmmanager.RebootBroadcastReceiver"
    android:enabled="false"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

Finally, add your audio asset(s) to your project like usual.

## How to use

Add to your pubspec.yaml:
```Bash
flutter pub add alarm
```

First, you have to initialize the Alarm service in your `main` function:
```Dart
await Alarm.init()
```

Then, you have to define your alarm settings:
```Dart
final alarmSettings = AlarmSettings(
  id: 42,
  dateTime: dateTime,
  assetAudioPath: 'assets/alarm.mp3',
  loopAudio: true,
  fadeDuration: 3.0,
  notificationTitle: 'This is the title',
  notificationBody: 'This is the body',
  enableNotificationOnKill: true,
);
```

And finally set the alarm:
```Dart
await Alarm.set(settings: alarmSettings)
```

Property |   Type     | Description
-------- |------------| ---------------
id |   `int`     | Unique identifier of the alarm.
alarmDateTime |   `DateTime`     | The date and time you want your alarm to ring.
assetAudio |   `String`     | The path to you audio asset you want to use as ringtone. Can be local asset or network URL.
loopAudio |   `bool`     | If true, audio will repeat indefinitely until it is stopped.
fadeDuration |   `double`     | Duration, in seconds, over which to fade the alarm volume. Set to 0 by default, which means no fade.
notificationTitle |   `String`     | The title of the notification triggered when alarm rings if app is on background.
notificationBody | `String` | The body of the notification.
enableNotificationOnKill |   `bool`     | Whether to show a notification when application is killed to warn the user that the alarm he set may not ring. Enabled by default.
