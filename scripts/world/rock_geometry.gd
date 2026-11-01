extends RefCounted
## The same mesh, deterministic placement and scale used by WorldView's rocks.
const ROCKS := ["nature/stone_largeA","nature/stone_largeB","nature/stone_largeC","nature/stone_tallA","nature/stone_tallB"]
static var cache := {}
static var triangles := {}
static var hulls := {}
static var work_points := {}

static func noise(x: int,y: int,k: int) -> float:
	var n := (x*374761393+y*668265263+k*2147483)&0x7fffffff
	n = ((n^(n>>13))*1274126177)&0x7fffffff
	return float(n%10000)/10000.0

static func bounds(c: Vector2i) -> Rect2:
	if cache.has(c): return cache[c]
	var mesh := Models.mesh(ROCKS[int(noise(c.x,c.y,12)*ROCKS.size())])
	var scale := 1.3+noise(c.x,c.y,13)*0.8
	var offset := Vector2(noise(c.x,c.y,40),noise(c.x,c.y,50))*0.6+Vector2.ONE*0.2
	var transform := Transform3D(Basis(Vector3.UP,noise(c.x,c.y,60)*TAU).scaled(Vector3.ONE*scale),Vector3(c.x+offset.x,0,c.y+offset.y))
	var box: AABB = transform*mesh.get_aabb()
	var rect := Rect2(Vector2(box.position.x,box.position.z)*Bal.CELL,Vector2(box.size.x,box.size.z)*Bal.CELL)
	var faces := mesh.get_faces()
	var points := PackedVector2Array()
	for i in faces.size():
		faces[i] = transform*faces[i]
		points.append(Vector2(faces[i].x,faces[i].z)*Bal.CELL)
	triangles[c] = faces
	hulls[c] = Geometry2D.convex_hull(points)
	cache[c] = rect
	return rect

static func blocked(p: Vector2) -> bool:
	var cell := Vector2i((p/Bal.CELL).floor())
	for x in range(cell.x-2,cell.x+3):
		for y in range(cell.y-2,cell.y+3):
			var c := Vector2i(x,y)
			if Terrain.kind(c)=="rock" and contains(c,p,Bal.CELL*0.16): return true
	return false


static func contains(c: Vector2i,p: Vector2,margin: float) -> bool:
	if not bounds(c).grow(margin).has_point(p): return false
	var hull: PackedVector2Array = hulls[c]
	if Geometry2D.is_point_in_polygon(p,hull): return true
	for i in hull.size()-1:
		if Geometry2D.get_closest_point_to_segment(p,hull[i],hull[i+1]).distance_to(p)<margin: return true
	return false

static func ray(c: Vector2i, start: Vector3, end: Vector3) -> Vector3:
	bounds(c)
	var faces: PackedVector3Array = triangles[c]
	var nearest := Vector3.INF
	var distance := INF
	for i in range(0,faces.size(),3):
		var hit = Geometry3D.segment_intersects_triangle(start,end,faces[i],faces[i+1],faces[i+2])
		if hit != null and start.distance_squared_to(hit)<distance:
			distance = start.distance_squared_to(hit)
			nearest = hit
	return nearest

# This is the existing pickaxe tip at contact, with unchanged arm/tool lengths.
static func impact_offset() -> Vector3:
	return (Vector3(0,0.50,0.40)+Basis(Vector3.RIGHT,2.10)*Vector3(0,0.735,-0.364))*0.46

static func spots(c: Vector2i) -> Array:
	if work_points.has(c): return work_points[c]
	var rect := bounds(c)
	var middle := rect.get_center()/Bal.CELL
	var offset := impact_offset()
	var result := []
	for i in 32:
		var direction := Vector2.from_angle(i*TAU/32)
		var center := Vector3(middle.x,offset.y,middle.y)
		var out := Vector3(direction.x,0,direction.y)
		var hit := ray(c,center+out*5.0,center-out*5.0)
		if hit == Vector3.INF: continue
		var stand := Vector2(hit.x,hit.z)*Bal.CELL+direction*offset.z*Bal.CELL
		if not contains(c,stand,Bal.CELL*0.16): result.append({"stand":stand,"hit":hit})
	work_points[c] = result
	return result

static func contact(c: Vector2i, stand: Vector2) -> Vector3:
	for spot in spots(c):
		if spot.stand.distance_to(stand)<1.0: return spot.hit
	return Vector3.INF
