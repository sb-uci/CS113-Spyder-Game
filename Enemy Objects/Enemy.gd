extends KinematicBody2D

var speed = 75
onready var player = get_parent().get_node("Astronaut")
onready var navigation = get_parent().get_node("Navigation")

func _physics_process(delta):
	var move_vectors = navigate(speed * delta, global_position, player.global_position)
	for vector in move_vectors:
		self.position += vector # move entity, ignoring collision
	move_and_slide(Vector2(0,0)) # apply collision after movement
	
# Explanation for above: using collision movement will cause weird movement
# around corners (entity running into object, causing slow movement).
# By ignoring collision, the entity moves more "smoothly" (i.e. regular speed).
# But this can cause it to partially clip into obstacles (never fully clip,
# though). To avoid that, collision is applied on a non-movement after movement.

func navigate(move_distance, start, end):
	var path = navigation.get_simple_path(start, end, true)
	path.remove(0) # first point is start point
	
	var vectors = [] # discreet movement steps
	for i in range(path.size()):
		var distance_to_point = start.distance_to(path[0])
		var move_vector = (path[0] - start).normalized()
		if move_distance <= distance_to_point:
			# entity CAN'T move all the way to next point
			vectors.append(move_vector * move_distance)
			break
		elif move_distance < 0:
			break
		else:
			# entity CAN move all teh way to next point
			vectors.append(move_vector * distance_to_point)
			move_distance -= distance_to_point
			start = path[0]
			path.remove(0)
	
	return vectors
