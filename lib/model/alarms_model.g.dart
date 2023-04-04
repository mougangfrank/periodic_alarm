// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarms_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlarmModel _$AlarmModelFromJson(Map<String, dynamic> json) => AlarmModel(
      id: json['id'] as int,
      dateTime: DateTime.parse(json['date_time'] as String),
      assetAudioPath: json['asset_audio_path'] as String,
      loopAudio: json['loop_audio'] as bool? ?? true,
      fadeDuration: (json['fade_duration'] as num?)?.toDouble() ?? 0.0,
      notificationTitle: json['notification_title'] as String?,
      notificationBody: json['notification_body'] as String?,
      enableNotificationOnKill:
          json['enable_notification_on_kill'] as bool? ?? true,
      monday: json['monday'] as bool? ?? false,
      tuesday: json['tuesday'] as bool? ?? false,
      wednesday: json['wednesday'] as bool? ?? false,
      thursday: json['thursday'] as bool? ?? false,
      friday: json['friday'] as bool? ?? false,
      saturday: json['saturday'] as bool? ?? false,
      sunday: json['sunday'] as bool? ?? false,
      active: json['active'] as bool? ?? false,
      snooze: json['snooze'] as int? ?? 8,
      musicTime: json['music_time'] as int? ?? 10,
      incMusicTime: (json['inc_music_time'] as num?)?.toDouble() ?? 5.0,
      musicVolume: (json['music_volume'] as num?)?.toDouble() ?? 1.0,
      incMusicVolume: (json['inc_music_volume'] as num?)?.toDouble() ?? 0.5,
    );

Map<String, dynamic> _$AlarmModelToJson(AlarmModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date_time': instance.dateTime.toIso8601String(),
      'asset_audio_path': instance.assetAudioPath,
      'loop_audio': instance.loopAudio,
      'fade_duration': instance.fadeDuration,
      'notification_title': instance.notificationTitle,
      'notification_body': instance.notificationBody,
      'enable_notification_on_kill': instance.enableNotificationOnKill,
      'monday': instance.monday,
      'tuesday': instance.tuesday,
      'wednesday': instance.wednesday,
      'thursday': instance.thursday,
      'friday': instance.friday,
      'saturday': instance.saturday,
      'sunday': instance.sunday,
      'active': instance.active,
      'snooze': instance.snooze,
      'music_time': instance.musicTime,
      'inc_music_time': instance.incMusicTime,
      'music_volume': instance.musicVolume,
      'inc_music_volume': instance.incMusicVolume,
    };
