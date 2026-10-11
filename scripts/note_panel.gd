extends Control

@onready var note_text: Label = $paper/MarginContainer/NoteText
@onready var hint: Label = $Hint

var pages: PackedStringArray = []
var current_page: int = 0


func _ready() -> void:
	visible = false

func show_note(new_pages: PackedStringArray) -> void:
	pages = new_pages
	current_page = 0
	visible = true
	_refresh()


func hide_note() -> void:
	visible = false


func next_page() -> bool:
	if current_page + 1 >= pages.size():
		return false

	current_page += 1
	_refresh()
	return true


func _refresh() -> void:
	if pages.is_empty():
		note_text.text = ""
		return

	note_text.text = pages[current_page]

	if current_page + 1 < pages.size():
		hint.text = "[E] next    [Esc] close"
	else:
		hint.text = "[E] close"
