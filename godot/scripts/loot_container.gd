extends Area3D
class_name LootContainer3D

@export var search_time := 2.0
@export var container_label := "Sandık"
var searched := false
var searching := false
var search_progress := 0.0
var loot_table := {
    "wood_plank": Vector2i(1, 4),
    "scrap_metal": Vector2i(1, 3),
    "wire_roll": Vector2i(1, 2),
    "cloth": Vector2i(1, 3),
    "alcohol": Vector2i(1, 2)
}

func _ready() -> void:
    add_to_group("loot_containers")
    monitoring = true

func begin_search() -> void:
    if searched or searching:
        return
    searching = true
    search_progress = 0.0

func _process(delta: float) -> void:
    if not searching:
        return
    search_progress += delta
    if search_progress >= search_time:
        searching = false
        searched = true
        var player := get_tree().get_first_node_in_group("player")
        if is_instance_valid(player):
            _distribute_loot(player)

func _distribute_loot(player: Node) -> void:
    var inventory: Node = player.get_node_or_null("InventoryManager")
    if not is_instance_valid(inventory):
        return
    var found: Array[String] = []
    var roll_count := randi_range(2, 3)
    var keys: Array = loot_table.keys()
    keys.shuffle()
    for i in range(roll_count):
        var item_id: String = str(keys[i])
        var bounds: Vector2i = loot_table[item_id]
        var amount := randi_range(bounds.x, bounds.y)
        var overflow := inventory.add_item(item_id, amount)
        var accepted := amount - overflow
        if accepted > 0:
            found.append("%s x%d" % [inventory.ITEMS[item_id].name, accepted])
    if found.is_empty():
        player._notify("Çanta dolu veya sandık boş")
    else:
        player._notify("Bulundu: " + ", ".join(found))

func get_status_text() -> String:
    if searched:
        return "%s (boş)" % container_label
    if searching:
        return "Aranıyor... %d%%" % int(search_progress / search_time * 100.0)
    return "%s — E: Ara" % container_label
