extends Node

# WARNING: not efficient for larger arguments of "size"

var container = []
var container_size

func set_size(size):
	container_size = size

func size():
	return container.size()

func append(object):
	container.append(object)
	if container.size() > container_size:
		container.pop_front()

func get_container():
	return container.duplicate()

func get(index):
	return container[index]
