extends Node
class_name Toggleable

@onready var target: Node = get_parent()

var disconnected_signals = []
var enabled: bool = true
	
func enable() -> void:
	if enabled:
		return
		
	# Enable all types of processing
	target.set_process(true)
	target.set_physics_process(true)
	target.set_process_input(true)
	target.set_process_unhandled_input(true)
	target.set_process_unhandled_key_input(true)

	# Reconnect signals if they were stored
	for signal_data in disconnected_signals:
		signal_data.signal.connect(signal_data.callable, signal_data.flags)
	disconnected_signals.clear()
	
	enabled = true

	
func disable() -> void:
	if not enabled:
		return
		
	target.set_process(false)
	target.set_physics_process(false)
	target.set_process_input(false)
	target.set_process_unhandled_input(false)
	target.set_process_unhandled_key_input(false)

	var signal_list = target.get_incoming_connections()
	for s in signal_list:
		disconnected_signals.append({
			'signal': s.signal,
			'callable': s.callable,
			'flags': s.flags
		})
		s.signal.disconnect(s.callable)
		
	enabled = false
	
