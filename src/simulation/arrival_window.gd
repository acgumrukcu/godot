class_name ArrivalWindow
extends RefCounted

# Bir müşteri tipinin geldiği saat aralığı. start_hour dahil, end_hour hariç.

var start_hour: int = 0
var end_hour: int = 0
var customers_per_hour: int = 0


func _init(p_start_hour: int, p_end_hour: int, p_customers_per_hour: int) -> void:
	start_hour = p_start_hour
	end_hour = p_end_hour
	customers_per_hour = p_customers_per_hour


func contains_hour(hour: int) -> bool:
	return hour >= start_hour and hour < end_hour
