extends Node
## Daily shared-world clock (Turkey UTC+3). Clients derive identical phase from Unix time.
signal broadcast_changed(message: String, urgent: bool)
signal phase_changed(is_purge: bool)

const TURKEY_OFFSET_SECONDS := 3 * 60 * 60
const PURGE_START := 19 * 60 * 60
const PURGE_END := 7 * 60 * 60
var is_purge_night := false
var _last_second := -1
var _last_announcement_key := ""
var _last_news_minute := -1

func _ready() -> void:
    _update_clock()
    _last_second = int(Time.get_unix_time_from_system())

func _process(_delta: float) -> void:
    var now := int(Time.get_unix_time_from_system())
    if now == _last_second:
        return
    _last_second = now
    _update_clock()

func _update_clock() -> void:
    var local_seconds := int(Time.get_unix_time_from_system()) + TURKEY_OFFSET_SECONDS
    var seconds_today := posmod(local_seconds, 86400)
    var day_number := floori(float(local_seconds) / 86400.0)
    var night_now := seconds_today >= PURGE_START or seconds_today < PURGE_END
    if night_now != is_purge_night:
        is_purge_night = night_now
        phase_changed.emit(is_purge_night)
    var until_start := posmod(PURGE_START - seconds_today, 86400)
    var until_end := posmod(PURGE_END - seconds_today, 86400)
    if is_purge_night:
        var key := "end_%d" % day_number if seconds_today < PURGE_END else "start_%d" % day_number
        if seconds_today >= PURGE_START and _last_announcement_key != key:
            _last_announcement_key = key
            _announce("DİKKAT. RESET NIGHT ARINMA DÖNEMİ BAŞLAMIŞTIR. Saat 19.00. Acil servisler ve güvenli bölgeler dışındaki alanlarda kendi güvenliğinizden siz sorumlusunuz. Sabah 07.00'ye kadar içeride kalın ve güvenliğinizi sağlayın.", true)
        elif seconds_today < PURGE_END and _last_announcement_key != key:
            _last_announcement_key = key
            _announce("RESET NIGHT ARINMA DÖNEMİ SONA ERMİŞTİR. Saat 07.00. Tüm şiddet ve suç eylemleri yasaktır. Günlük hayatınıza güvenli biçimde dönebilirsiniz.", true)
        _set_status("ARINMA AKTİF  •  BİTİŞE " + _format_time(until_end))
    else:
        _set_status("NORMAL HAYAT  •  ARINMAYA " + _format_time(until_start))
        var minute := floori(float(seconds_today) / 60.0)
        if minute != _last_news_minute and seconds_today >= 12 * 60 * 60 and seconds_today < PURGE_START and minute % 30 == 0:
            _last_news_minute = minute
            var remaining_hours := ceili(float(until_start) / 3600.0)
            if remaining_hours <= 6:
                _announce("Son dakika. Bu yılki RESET NIGHT arınmasına %d saatten az süre kaldı. Başlangıç saati 19.00. Güvenli alanınızı önceden belirleyin." % remaining_hours, false)

func _format_time(total_seconds: int) -> String:
    var hours := int(total_seconds / 3600)
    var minutes := int((total_seconds % 3600) / 60)
    var seconds := total_seconds % 60
    return "%02d:%02d:%02d" % [hours, minutes, seconds]

func _set_status(value: String) -> void:
    broadcast_changed.emit(value, false)

func _announce(value: String, urgent: bool) -> void:
    broadcast_changed.emit(value, urgent)
    DisplayServer.tts_speak(value, "", 1.0, 1.0, 1.0, 0, true)

func current_status() -> String:
    var local_seconds := posmod(int(Time.get_unix_time_from_system()) + TURKEY_OFFSET_SECONDS, 86400)
    if local_seconds >= PURGE_START or local_seconds < PURGE_END:
        return "ARINMA AKTİF  •  BİTİŞE " + _format_time(posmod(PURGE_END - local_seconds, 86400))
    return "NORMAL HAYAT  •  ARINMAYA " + _format_time(posmod(PURGE_START - local_seconds, 86400))
