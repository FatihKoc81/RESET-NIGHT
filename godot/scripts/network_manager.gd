extends Node

signal lobby_status_changed(message: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

const DEFAULT_PORT := 2456
var game_mode := "solo"
var player_side := "defense"
var is_host := false
var status_text := "Lobi bağlantısı yok."
var connected_peers: Array[int] = []

func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(port: int = DEFAULT_PORT, max_clients: int = 3) -> int:
    close_session(false)
    var peer := ENetMultiplayerPeer.new()
    var result := peer.create_server(port, clampi(max_clients, 1, 3))
    if result != OK:
        _set_status("Sunucu açılamadı. Port %d kullanılıyor olabilir." % port)
        return result
    multiplayer.multiplayer_peer = peer
    is_host = true
    game_mode = "coop"
    connected_peers.clear()
    _set_status("Oda hazır • Port: %d • IP: %s • Oyuncular: 1/4" % [port, _local_ip()])
    return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> int:
    close_session(false)
    var peer := ENetMultiplayerPeer.new()
    var result := peer.create_client(address, port)
    if result != OK:
        _set_status("Sunucuya bağlanılamadı. IP ve portu kontrol et.")
        return result
    multiplayer.multiplayer_peer = peer
    is_host = false
    game_mode = "coop"
    _set_status("%s:%d adresine bağlanılıyor..." % [address, port])
    return OK

func close_session(emit_status: bool = true) -> void:
    if multiplayer.multiplayer_peer != null:
        multiplayer.multiplayer_peer.close()
        multiplayer.multiplayer_peer = null
    is_host = false
    connected_peers.clear()
    if emit_status:
        _set_status("Lobi bağlantısı kapatıldı.")

func _on_peer_connected(id: int) -> void:
    if not connected_peers.has(id):
        connected_peers.append(id)
    _set_status("Oyuncu bağlandı • Oyuncular: %d/4" % (connected_peers.size() + 1))
    peer_joined.emit(id)

func _on_peer_disconnected(id: int) -> void:
    connected_peers.erase(id)
    _set_status("Oyuncu ayrıldı • Oyuncular: %d/4" % (connected_peers.size() + (1 if is_host else 0)))
    peer_left.emit(id)

func _on_connected_to_server() -> void:
    _set_status("Oda bağlantısı kuruldu. Oda sahibinin oyunu başlatmasını bekle.")

func _on_connection_failed() -> void:
    close_session(false)
    _set_status("Bağlantı başarısız. Aynı ağda olduğunuzu ve port %d erişimini kontrol edin." % DEFAULT_PORT)

func _on_server_disconnected() -> void:
    close_session(false)
    _set_status("Oda sahibi bağlantıyı kapattı.")

func _local_ip() -> String:
    for address in IP.get_local_addresses():
        if address.contains(".") and not address.begins_with("127.") and not address.begins_with("169.254."):
            return address
    return "IP bulunamadı"

func _set_status(message: String) -> void:
    status_text = message
    lobby_status_changed.emit(message)
