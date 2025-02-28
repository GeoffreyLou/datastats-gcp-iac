# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Network & subnetwork
# ----------------------------------------------------------------------------------------------------------------------

resource "google_compute_network" "datastats_network" {
  project                 = var.project_id
  name                    = "${var.project_name}-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "datastats_subnetwork" {
  name                     = "${var.project_name}-subnetwork"
  ip_cidr_range            = "180.0.0.0/16"
  region                   = var.region
  project                  = var.project_id
  network                  = google_compute_network.datastats_network.id
  private_ip_google_access = true
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Cloud SQL Private IP
# ----------------------------------------------------------------------------------------------------------------------

resource "google_compute_global_address" "cloudsql_private_ip" {
  project       = var.project_id
  name          = "${var.project_name}-cloudsql-psc-address"
  prefix_length = 16
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  network       = google_compute_network.datastats_network.id
} 


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 VPC peering
# ----------------------------------------------------------------------------------------------------------------------

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.datastats_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.cloudsql_private_ip.name]
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Serverless VPC connector
# ----------------------------------------------------------------------------------------------------------------------

# TODO: remove and replace creation / deletion in workflows to avoid costs

resource "google_vpc_access_connector" "serverless_connector" {
  name          = "${var.project_name}-connector"
  project       = var.project_id
  region        = var.region
  ip_cidr_range = "10.10.0.0/28"
  network       = google_compute_network.datastats_network.name
  machine_type  = "e2-micro"
  min_instances = 2
  max_instances = 3
}
