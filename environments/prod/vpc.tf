# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Context
# ----------------------------------------------------------------------------------------------------------------------

/*
  TODO: remove and replace creation / deletion of google_vpc_access_connector in workflows to avoid costs
  TODO: remove and replace creation / deletion of nat and router in workflows to avoid costs
*/

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

resource "google_compute_global_address" "peering_ip" {
  project       = var.project_id
  name          = "${var.project_name}-peering-ip"
  prefix_length = 16
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  network       = google_compute_network.datastats_network.id
  labels        = { env = var.env }
} 


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 VPC peering
# ----------------------------------------------------------------------------------------------------------------------

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.datastats_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.peering_ip.name]
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Serverless VPC connector
# ----------------------------------------------------------------------------------------------------------------------

# TODO : delete because of costs, created and deleted in cloud workflows

/* resource "google_vpc_access_connector" "serverless_connector" {
  name          = "${var.project_name}-connector"
  project       = var.project_id
  region        = var.region
  ip_cidr_range = "10.10.0.0/28"
  network       = google_compute_network.datastats_network.name
  machine_type  = "e2-micro"
  min_instances = 2
  max_instances = 3
} */


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Cloud Router & Nat
# ----------------------------------------------------------------------------------------------------------------------

# TODO : delete because of costs, created and deleted in cloud workflows

/* resource "google_compute_router" "datastats_router" {
  name    = "${var.project_name}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.datastats_network.id
}

resource "google_compute_router_nat" "datastats_nat" {
  name                               = "${var.project_name}-nat"
  project                            = var.project_id
  router                             = google_compute_router.datastats_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
 */