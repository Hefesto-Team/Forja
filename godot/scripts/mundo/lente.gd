class_name Lente
## A lente em mm vira FOV vertical (arte/01): sensor de 24 mm de altura.
static func fov(mm: float) -> float:
	return rad_to_deg(2.0 * atan(12.0 / mm))


## O FOV de hoje (40°) em mm, para quem ainda não tem lente decidida.
const PADRAO := 32.97


## Quanto a pose fixa recua para a lente `mm` ver o mesmo que os 40° viam.
static func recuo(mm: float) -> float:
	return mm / PADRAO
