extends Navigation2D

# Called when the node enters the scene tree for the first time.
func _ready():
	generate_mesh()
	var mesh = $NavMesh.get_navigation_polygon().get_outline_count()
	get_node("NavMesh").enabled = false
	get_node("NavMesh").enabled = true

# iterates through children of navigation, gets their collision polygons, and
# cuts them out of navigation mesh
func generate_mesh():
	var mesh = $NavMesh.get_navigation_polygon()
	for child in self.get_children():
		if child.get_class() == "StaticBody2D":
			var polygons = []
			for grand_child in child.get_children():
				if grand_child.get_class() == "CollisionPolygon2D":
					# add cutout to navmesh
					polygons.append(_create_cutout(grand_child))
				if grand_child.get_class() == "StaticBody2D":
					var collision_child = _find_collision_node(grand_child)
					polygons.append(_create_cutout(collision_child))
			mesh.add_outline(_merge_polygons(polygons))
					
	mesh.make_polygons_from_outlines()
	$NavMesh.set_navigation_polygon(mesh)

func _create_cutout(collision_node):
	var new_cutout = PoolVector2Array()
	var poly_transform = collision_node.get_global_transform()
	var poly_points = collision_node.get_polygon()
	
	# apply transform
	for vertex in poly_points:
		new_cutout.append(poly_transform.xform(vertex))
	return new_cutout

func _find_collision_node(parent):
	for child in parent.get_children():
		if child.get_class() == "CollisionPolygon2D":
			return child

func _merge_polygons(poly_array):
	var new_poly = poly_array[0]
	for i in range(poly_array.size() - 1):
		var merged_polys = Geometry.merge_polygons_2d(new_poly, poly_array[i+1])
		new_poly = merged_polys[0]
	return new_poly
