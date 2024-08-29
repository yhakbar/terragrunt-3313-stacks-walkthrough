unit "api" {
	source = "../../../../units/api"
	path   = "services/api"
}

unit "canary_api" {
	source = "../../../../units/api"
	path   = "services/canary-api"
}

unit "backup_api" {
	source = "../../../../units/api"
	path   = "services/backup-api"
}

unit "db" {
	source = "../../../../units/db"
	path   = "storage/db"
}
