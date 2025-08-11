extends Node


enum FormatStyle { WORDS, SCIENTIFIC }

# Default format style — can be changed at runtime
var number_format: FormatStyle = FormatStyle.WORDS

# Public method to format a number based on style
func format(n: float) -> String:
	match number_format:
		FormatStyle.WORDS:
			return format_words(n)
		FormatStyle.SCIENTIFIC:
			return format_scientific(n)
		_:
			return str(n)

# Word notation (K, M, B, T...)
func format_words(n: float) -> String:
	var suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var index = 0
	while n >= 1000.0 and index < suffixes.size() - 1:
		n /= 1000.0
		index += 1
	return str(round(n * 100.0) / 100.0) + suffixes[index]

# Scientific notation (e.g. 1.23e6)
func format_scientific(n: float) -> String:
	if n < 1000:
		return str(n)
	var exponent = floor(log(n) / log(10))
	var mantissa = n / pow(10, exponent)
	return str(round(mantissa * 100.0) / 100.0) + "e" + str(int(exponent))
	
	
	
