class_name Lente
extends RefCounted


static func fov(mm: float) -> float:
	return rad_to_deg(2.0 * atan(12.0 / mm))


const PADRAO := 32.97


static func recuo(mm: float) -> float:
	return mm / PADRAO
