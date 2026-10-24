extends GutTest


func test_jump_edge_bits() -> void:
	var f := InputFrame.new()
	f.buttons = InputFrame.BTN_JUMP_HELD | InputFrame.BTN_JUMP_PRESSED
	assert_true(f.pressed(InputFrame.BTN_JUMP_PRESSED))
	assert_true(f.pressed(InputFrame.BTN_JUMP_HELD))
	var held := InputFrame.new()
	held.buttons = InputFrame.BTN_JUMP_HELD
	assert_false(held.pressed(InputFrame.BTN_JUMP_PRESSED))
	assert_true(held.pressed(InputFrame.BTN_JUMP_HELD))
