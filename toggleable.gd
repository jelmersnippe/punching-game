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
		target.connect(signal_data['signal'], signal_data['target'], signal_data['method'])
	disconnected_signals.clear()

	
func disable() -> void:
	if not enabled:
		return
		
	target.set_process(false)
	target.set_physics_process(false)
	target.set_process_input(false)
	target.set_process_unhandled_input(false)
	target.set_process_unhandled_key_input(false)

	# Disconnect and store signals
	var signal_list = target.get_signal_list()
	for s in signal_list:
		disconnected_signals.append({
			'signal': s.signal,
			'target': s.target,
			'method': s.method
		})
		target.disconnect(s.signal, s.method)
	
