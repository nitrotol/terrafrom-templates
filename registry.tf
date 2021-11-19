resource "google_container_registry" "this" {
  project  = data.google_project.this.project_id
  location = "EU"
}

resource "google_service_account" "registry" {
  account_id   = "${data.google_project.this.name}-registry"
  display_name = "${data.google_project.this.name}-registry"
  description  = "${data.google_project.this.name} Registry"
}

resource "google_project_iam_member" "registry" {
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.registry.email}"
}

resource "google_service_account_key" "registry" {
  service_account_id = google_service_account.registry.name
}

resource "google_storage_bucket_iam_member" "viewer" {
  bucket = google_container_registry.this.id
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.kubernetes.email}"
}
