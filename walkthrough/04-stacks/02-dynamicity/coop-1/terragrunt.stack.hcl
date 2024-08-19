locals {
	mother_name = "Pecky"
	father_name = "Cawrl"
}

unit "mother" {
	source = "../../units/mother"
	path   = "mother"
}

unit "father" {
	source = "../../units/father"
	path   = "father"
}

unit "chick_1" {
	source = "../../units/chick"
	path   = "chicks/chick-1"
}

unit "chick_2" {
	source = "../../units/chick"
	path   = "chicks/chick-2"
}

