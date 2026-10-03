extends GdUnitTestSuite
## Every translation key must ship with both English and Italian text.

const TRANSLATIONS_PATH: String = "res://locale/translations.csv"
const EXPECTED_HEADER: PackedStringArray = ["keys", "en", "it"]


func test_header_lists_english_and_italian() -> void:
	var rows: Array[PackedStringArray] = _read_rows()
	assert_array(rows).is_not_empty()
	if rows.is_empty():
		return
	assert_array(rows[0]).is_equal(EXPECTED_HEADER)


func test_every_key_has_text_in_every_language() -> void:
	var rows: Array[PackedStringArray] = _read_rows()
	for row: PackedStringArray in rows.slice(1):
		assert_int(row.size()).is_equal(EXPECTED_HEADER.size())
		for column: int in range(1, mini(row.size(), EXPECTED_HEADER.size())):
			var message: String = "Key '%s' has no '%s' text" % [row[0], EXPECTED_HEADER[column]]
			assert_str(row[column]).override_failure_message(message).is_not_empty()


func test_keys_are_unique() -> void:
	var seen: Dictionary[String, bool] = {}
	for row: PackedStringArray in _read_rows().slice(1):
		var message: String = "Duplicate key '%s'" % row[0]
		assert_bool(seen.has(row[0])).override_failure_message(message).is_false()
		seen[row[0]] = true


func _read_rows() -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var file: FileAccess = FileAccess.open(TRANSLATIONS_PATH, FileAccess.READ)
	assert_object(file).is_not_null()
	if file == null:
		return rows
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		# The trailing newline yields one empty row at the end of the file.
		if row.size() == 1 and row[0].is_empty():
			continue
		rows.append(row)
	return rows
