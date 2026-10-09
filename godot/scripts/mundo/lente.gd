class_name Lente
extends RefCounted
## A lente em mm vira FOV vertical (arte/01): sensor de 24 mm de altura.
## 85 mm = 16,1°, 35 mm = 37,8°.


static func fov(mm: float) -> float:
	return rad_to_deg(2.0 * atan(12.0 / mm))


## O FOV de hoje (40°) em mm, para quem ainda não tem lente decidida.
const PADRAO := 32.97
