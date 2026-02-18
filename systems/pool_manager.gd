extends Node
## 적, 투사체, 드롭, 데미지 숫자의 오브젝트 풀을 관리한다.
## Autoload 싱글톤: PoolManager


# 씬 리소스 경로를 키로, 비활성 인스턴스 배열을 값으로 저장한다.
var _pools: Dictionary = {}
# 활성 인스턴스를 추적한다 (일괄 반환용).
var _active: Dictionary = {}


## 풀에서 인스턴스를 꺼낸다. 없으면 새로 생성한다.
func acquire(scene: PackedScene) -> Node:
	var key := scene.resource_path
	_ensure_pool_exists(key)

	var instance: Node
	if _pools[key].size() > 0:
		instance = _pools[key].pop_back()
	else:
		instance = scene.instantiate()

	_active[key].append(instance)
	return instance


## 인스턴스를 풀에 반환한다.
func release(scene: PackedScene, instance: Node) -> void:
	var key := scene.resource_path
	_ensure_pool_exists(key)

	if instance.get_parent() != null:
		instance.get_parent().remove_child(instance)

	_active[key].erase(instance)
	_pools[key].append(instance)


## 특정 씬의 모든 활성 인스턴스를 반환한다.
func release_all(scene: PackedScene) -> void:
	var key := scene.resource_path
	_ensure_pool_exists(key)

	for instance: Node in _active[key].duplicate():
		release(scene, instance)


## 풀을 미리 워밍업한다.
func prewarm(scene: PackedScene, count: int) -> void:
	var key := scene.resource_path
	_ensure_pool_exists(key)

	for i in range(count):
		var instance := scene.instantiate()
		_pools[key].append(instance)


func _ensure_pool_exists(key: String) -> void:
	if not _pools.has(key):
		_pools[key] = []
		_active[key] = []
