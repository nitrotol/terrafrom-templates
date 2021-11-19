resource "google_compute_global_address" "mysql" {
  name          = "${data.google_project.this.name}-db"
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  prefix_length = 16
  network       = module.vpc.network_id
  project       = data.google_project.this.name
}

resource "google_service_networking_connection" "mysql" {
  network                 = module.vpc.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.mysql.name]
}

resource "random_id" "mysql" {
  byte_length = 4
}

resource "google_sql_database_instance" "this" {
  name             = "${data.google_project.this.name}-${random_id.mysql.hex}"
  region           = data.google_client_config.this.region
  database_version = "MYSQL_8_0"
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = module.vpc.network_id
    }
  }
  depends_on = [
    google_service_networking_connection.mysql
  ]
}

resource "kubernetes_service" "mysql" {
  metadata {
    name = "mysql"
  }
  spec {
    type          = "ExternalName"
    external_name = google_sql_database_instance.this.private_ip_address
  }
}

resource "google_sql_database" "this" {
  name      = "this"
  instance  = google_sql_database_instance.this.name
  charset   = "utf8mb4"
  collation = "utf8mb4_bin"
}

resource "random_password" "gitpod_mysql" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "google_sql_user" "this" {
  name     = "this"
  instance = google_sql_database_instance.this.name
  host     = "10.%"
  password = random_password.gitpod_mysql.result
}

resource "google_compute_network_peering_routes_config" "mysql" {
  for_each = [
    "servicenetwork",
    "cloudsql-mysql"
  ]
  peering = "${each.value}-googleapis-com"
  network = module.vpc.network_name

  import_custom_routes = true
  export_custom_routes = true

  depends_on = [
    google_sql_database_instance.this
  ]
}
