data "google_project" "this" {}

data "google_client_config" "this" {}

resource "google_project_service" "this" {
  for_each = toset([
    # TODO Feel me
  ])
  project = data.google_project.this.id
  service = "${each.value}.googleapis.com"

}
