# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Context
# ----------------------------------------------------------------------------------------------------------------------

/*
  To connect to Cloud SQL Private IP, we need to create a bastion host with a Cloud SQL Proxy.
  This bastion is only used in dev environment to create dbt models through VScode in my local machine.
  It is not used in prod environment.
*/

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Service Account and roles
# ----------------------------------------------------------------------------------------------------------------------

resource "google_service_account" "bastion_sql_proxy" {
  account_id   = "bastion-sql-proxy"
  display_name = "Bastion Cloud SQL Proxy"
  project      = var.project_id
}

resource "google_project_iam_member" "bastion_sql_proxy_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.bastion_sql_proxy.email}"
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Bastion Compute Engine
# ----------------------------------------------------------------------------------------------------------------------

resource "google_compute_instance" "bastion" {
  depends_on = [ 
    google_compute_firewall.allow_ssh_from_ip,
    google_compute_firewall.allow_internet_access
  ]

  name         = "bastion"
  machine_type = "e2-micro"
  zone         = var.zone
  labels       = { env = var.env }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      labels = {
        env = var.env
      }
    }
  }

  network_interface {
    network    = google_compute_network.datastats_network.name
    subnetwork = google_compute_subnetwork.datastats_subnetwork.name
    access_config {} 
  }

  service_account {
    email  = google_service_account.bastion_sql_proxy.email
    scopes = ["cloud-platform"]
  }

  tags = ["bastion", "internet-access"]

  metadata_startup_script = <<-EOF
#!/bin/bash
cd /home
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.13.0/cloud-sql-proxy.linux.amd64
chmod +x cloud-sql-proxy
./cloud-sql-proxy ${google_sql_database_instance.datastats_sql.connection_name} --private-ip
EOF

  metadata = {
    enable-oslogin = "TRUE"
  }
}