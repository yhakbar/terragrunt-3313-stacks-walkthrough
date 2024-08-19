dependency "mother" {
	config_path = "../../mother"
}

dependency "father" {
	config_path = "../../father"
}

inputs = {
	mother = "${dependency.mother.outputs.first_name} ${dependency.mother.outputs.last_name}"
	father = "${dependency.father.outputs.first_name} ${dependency.father.outputs.last_name}"

	// From what I've gathered chickens live in a Matriarchy.
	last_name = dependency.mother.outputs.last_name
}

