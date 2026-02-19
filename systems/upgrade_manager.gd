extends Node
## 레벨업 선택지 생성, 무기/패시브 적용, 보물 상자 보상, 진화 체크를 담당한다.
## Autoload 싱글톤: UpgradeManager


signal upgrade_applied(data: UpgradeData)

var _upgrade_pool: Array[UpgradeData] = []
var _passive_pool: Array[PassiveData] = []
var _acquired_weapons: Array[String] = []
var _player: CharacterBody2D = null


func _ready() -> void:
	_load_upgrades()
	_load_passives()
	GameManager.state_changed.connect(_on_state_changed)


func register_player(player: CharacterBody2D) -> void:
	_player = player
	_acquired_weapons.clear()
	_acquired_weapons.append("res://entities/weapons/cursed_scissors.gd")


func generate_choices(count: int) -> Array[UpgradeData]:
	var available: Array[UpgradeData] = []

	# 기존 무기 레벨업 선택지
	if _player != null:
		for weapon: WeaponBase in _player._weapons:
			if weapon.level < weapon.data.max_level:
				var upgrade := UpgradeData.new()
				upgrade.upgrade_name = weapon.data.weapon_name
				upgrade.description = "Lv.%d → Lv.%d" % [weapon.level, weapon.level + 1]
				upgrade.card_color = weapon.data.projectile_color
				upgrade.stat_key = "weapon_levelup"
				upgrade.weapon_script_path = weapon.get_script().resource_path
				available.append(upgrade)

	# 패시브 레벨업 선택지
	if _player != null:
		for p_name: String in _player._passives:
			var info: Dictionary = _player._passives[p_name]
			var p_data: PassiveData = info["data"]
			var p_level: int = info["level"]
			if p_level < p_data.max_level:
				var upgrade := UpgradeData.new()
				upgrade.upgrade_name = p_data.passive_name
				upgrade.description = "Lv.%d → Lv.%d" % [p_level, p_level + 1]
				upgrade.card_color = p_data.icon_color
				upgrade.stat_key = "passive_levelup"
				upgrade.weapon_data_path = p_data.resource_path
				available.append(upgrade)

	# 새 패시브 선택지
	if _player != null:
		for p_data in _passive_pool:
			if _player._passives.has(p_data.passive_name):
				continue
			if _player._passives.size() >= Constants.MAX_PASSIVES:
				continue
			var upgrade := UpgradeData.new()
			upgrade.upgrade_name = p_data.passive_name
			upgrade.description = p_data.description
			upgrade.card_color = p_data.icon_color
			upgrade.stat_key = "new_passive"
			upgrade.weapon_data_path = p_data.resource_path
			available.append(upgrade)

	# 일반 업그레이드 + 새 무기 선택지
	for upgrade in _upgrade_pool:
		if upgrade.stat_key == "new_weapon":
			if upgrade.weapon_script_path in _acquired_weapons:
				continue
			if _player != null and _player._weapons.size() >= Constants.MAX_WEAPONS:
				continue
		available.append(upgrade)

	available.shuffle()
	var result: Array[UpgradeData] = []
	for i in range(mini(count, available.size())):
		result.append(available[i])
	return result


func apply_upgrade(data: UpgradeData) -> void:
	if _player == null:
		return

	match data.stat_key:
		"heal_percent":
			var heal: float = _player.max_hp * data.value
			_player.current_hp = minf(_player.current_hp + heal, _player.max_hp)
			_player.hp_changed.emit(_player.current_hp, _player.max_hp)
		"new_weapon":
			_equip_weapon(data)
		"weapon_levelup":
			_levelup_weapon(data)
		"new_passive":
			_acquire_passive(data)
		"passive_levelup":
			_levelup_passive(data)

	upgrade_applied.emit(data)


func _equip_weapon(data: UpgradeData) -> void:
	if data.weapon_script_path in _acquired_weapons:
		return
	var weapon_data: WeaponData = load(data.weapon_data_path)
	var script: GDScript = load(data.weapon_script_path)
	var weapon := Node2D.new()
	weapon.set_script(script)
	weapon.name = data.upgrade_name
	_player.add_child(weapon)
	weapon.initialize(weapon_data, _player)
	_player._weapons.append(weapon)
	_acquired_weapons.append(data.weapon_script_path)


func _levelup_weapon(data: UpgradeData) -> void:
	if _player == null:
		return
	for weapon: WeaponBase in _player._weapons:
		if weapon.get_script().resource_path == data.weapon_script_path:
			weapon.level_up()
			return


func _acquire_passive(data: UpgradeData) -> void:
	var passive_data: PassiveData = load(data.weapon_data_path)
	_player.add_passive(passive_data)


func _levelup_passive(data: UpgradeData) -> void:
	var passive_data: PassiveData = load(data.weapon_data_path)
	_player.levelup_passive(passive_data.passive_name)


func _load_upgrades() -> void:
	var paths := [
		"res://data/upgrades/heal.tres",
		"res://data/upgrades/weapon_cursed_bible.tres",
		"res://data/upgrades/weapon_ghost_candle.tres",
		"res://data/upgrades/weapon_cursed_bouquet.tres",
		"res://data/upgrades/weapon_doll_needle.tres",
		"res://data/upgrades/weapon_clock_gear.tres",
		"res://data/upgrades/weapon_mirror_shard.tres",
		"res://data/upgrades/weapon_witch_broom.tres",
	]
	for path in paths:
		var res := load(path)
		if res is UpgradeData:
			_upgrade_pool.append(res)


func _load_passives() -> void:
	var paths := [
		"res://data/passives/thick_apron.tres",
		"res://data/passives/running_shoes.tres",
		"res://data/passives/broken_clock.tres",
		"res://data/passives/cursed_necklace.tres",
		"res://data/passives/magnifying_glass.tres",
		"res://data/passives/magnet_brooch.tres",
		"res://data/passives/old_diary.tres",
		"res://data/passives/lucky_coin.tres",
		"res://data/passives/regen_herb.tres",
		"res://data/passives/ghost_cloak.tres",
	]
	for path in paths:
		var res := load(path)
		if res is PassiveData:
			_passive_pool.append(res)


func _on_state_changed(
		_old_state: Enums.GameState,
		new_state: Enums.GameState
) -> void:
	if new_state == Enums.GameState.MENU:
		_player = null
		_acquired_weapons.clear()
