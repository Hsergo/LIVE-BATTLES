extends SceneTree
## Local visual QA only. Screenshots always use the explicitly labeled DEMO.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var output := OS.get_environment("RESCUE_PREVIEW_DIR")
	if output.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.set("persistence_enabled",false)
	await create_timer(2.0).timeout
	await _capture(output+"/organizer.png")
	main.set("admin_visible",false)
	main.call("_update_controls")
	await create_timer(1.0).timeout
	await _capture(output+"/mission.png")
	var model: RefCounted = main.get("state")
	main.set_process(false)
	model.set("status","CHALLENGE")
	var session: RefCounted = model.get("marathon")
	session.set("challenge_seconds",90.0)
	for i in range(3):
		session.set("challenge_index",i)
		session.set("challenge_stage",1)
		session.set("challenge_progress",15.0)
		main.queue_redraw()
		await create_timer(3.0).timeout
		await _capture(output+"/support_%d.png" % i)
	model.set("status","SESSION_COMPLETE")
	main.queue_redraw()
	await _capture(output+"/summary.png")
	quit()

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(path)
	print("CAPTURE ",path," ",result)
