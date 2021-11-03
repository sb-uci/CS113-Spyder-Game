extends Navigation2D

# Called when the node enters the scene tree for the first time.
func _ready():
	generate_mesh()
	get_node("NavMesh").enabled = false
	get_node("NavMesh").enabled = true

# iterates through children of navigation, gets their collision polygons, and
# cuts them out of navigation mesh
func generate_mesh():
	var mesh = $NavMesh.get_navigation_polygon()
	for child in self.get_children():
		if child.get_class() == "StaticBody2D":
			for grand_child in child.get_children():
				if grand_child.get_class() == "CollisionPolygon2D":
					var new_cutout = PoolVector2Array()
					var poly_transform = grand_child.get_global_transform()
					var poly_points = grand_child.get_polygon()
					
					# apply transform
					for vertex in poly_points:
						new_cutout.append(poly_transform.xform(vertex))
				
					# add cutout to navmesh
					mesh.add_outline(new_cutout)
					
	mesh.make_polygons_from_outlines()
	$NavMesh.set_navigation_polygon(mesh)
