extends Node
## Player inventory and crafting data. Item amounts are stored by item ID.

signal inventory_changed

const ITEMS := {
    "wood_plank": {"name": "Tahta Parçası", "max_stack": 20},
    "scrap_metal": {"name": "Hurda Metal", "max_stack": 20},
    "wire_roll": {"name": "Dikenli Tel Yumağı", "max_stack": 10},
    "cloth": {"name": "Kumaş", "max_stack": 20},
    "alcohol": {"name": "Alkol", "max_stack": 10},
    "molotov": {"name": "Molotof", "max_stack": 5},
    "first_aid": {"name": "İlk Yardım Kiti", "max_stack": 5},
    "spiked_bat_upgrade": {"name": "Dikenli Sopa Takviyesi", "max_stack": 1}
}

const RECIPES := {
    "molotov": {"name": "Molotof", "cost": {"cloth": 1, "alcohol": 1}, "output": 1},
    "first_aid": {"name": "İlk Yardım Kiti", "cost": {"cloth": 2, "alcohol": 1}, "output": 1},
    "wire_trap": {"name": "Dikenli Tel Tuzağı", "cost": {"scrap_metal": 1, "wire_roll": 1}, "output": 1, "result_item": "wire_roll"},
    "spiked_bat_upgrade": {"name": "Dikenli Sopa Takviyesi", "cost": {"scrap_metal": 2, "wire_roll": 2}, "output": 1}
}

var inventory: Dictionary = {}

func _ready() -> void:
    for item_id in ITEMS:
        inventory[item_id] = 0

func add_item(item_id: String, amount: int) -> int:
    if not ITEMS.has(item_id) or amount <= 0:
        return amount
    var max_stack: int = ITEMS[item_id].max_stack
    var accepted := mini(amount, max_stack - int(inventory.get(item_id, 0)))
    inventory[item_id] = int(inventory.get(item_id, 0)) + accepted
    if accepted > 0:
        inventory_changed.emit()
    return amount - accepted

func has_items(cost: Dictionary) -> bool:
    for item_id in cost:
        if int(inventory.get(item_id, 0)) < int(cost[item_id]):
            return false
    return true

func remove_items(cost: Dictionary) -> bool:
    if not has_items(cost):
        return false
    for item_id in cost:
        inventory[item_id] = int(inventory.get(item_id, 0)) - int(cost[item_id])
    inventory_changed.emit()
    return true

func craft(recipe_id: String) -> bool:
    if not RECIPES.has(recipe_id):
        return false
    var recipe: Dictionary = RECIPES[recipe_id]
    var result_id: String = str(recipe.get("result_item", recipe_id))
    if int(inventory.get(result_id, 0)) >= int(ITEMS[result_id].max_stack):
        return false
    if not remove_items(recipe.cost):
        return false
    add_item(result_id, int(recipe.output))
    return true

func consume(item_id: String, amount: int = 1) -> bool:
    return remove_items({item_id: amount})

func get_inventory_text() -> String:
    var lines := ["ÇANTA"]
    for item_id in ITEMS:
        var count := int(inventory.get(item_id, 0))
        if count > 0:
            lines.append("%s: %d" % [ITEMS[item_id].name, count])
    if lines.size() == 1:
        lines.append("Henüz eşya yok")
    return "\n".join(lines)
