# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Context
# ----------------------------------------------------------------------------------------------------------------------

/*
  VPC is only used to connect to Cloud SQL Private IP and for VPC peering with Cloud SQL.

  When the Cloud Run Job is connected to the VPC, it will be able to access the Cloud SQL Private IP.
  But it will lost internet access.

  To avoid costs, VPC resources are created and deleted in the Cloud Workflow only when needed : 
  - Serverless VPC Connector
  - Cloud Router
  - Cloud NAT
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