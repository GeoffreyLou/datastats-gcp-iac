# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Context
# ----------------------------------------------------------------------------------------------------------------------

/*
  Documentation used to create connexion between Cloud Run and Cloud SQL with private IP:
  - https://cloud.google.com/sql/docs/postgres/connect-instance-cloud-run?hl=fr#gcloud_4

  To use a Cloud SQL instance with a private IP, you must create:
  - [VPC] a VPC network and a subnetwork with private IP Google access enabled
  - [VPC] a private IP address for the Cloud SQL instance
  - [VPC] a VPC peering for service.networking.googleapis.com
  - [VPC] a Serverless VPC connector
  - [CLOUD SQL] a Cloud SQL instance with a private IP and require SSL
  - [CLOUD SQL] a Cloud SQL user and password
  - [CLOUD SQL] a Cloud SQL database
  - [CLOUD SQL] a Cloud SQL user with the appropriate permissions
  - [CLOUD SQL] a SSL certificate from CLoud SQL

  APIs to activate: 
  - vpcaccess.googleapis.com
  - sqladmin.googleapis.com
  - secretmanager.googleapis.com
  - servicenetworking.googleapis.com
*/

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Root password
# ----------------------------------------------------------------------------------------------------------------------

resource "random_password" "root_password" {
  length  = 16
  special = true
}

resource "google_secret_manager_secret" "root_password_secret" {
  secret_id = "${var.project_name}-pgsql-root-password"
  project   = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = {
    env = var.env
  }
}

resource "google_secret_manager_secret_version" "root_password_version" {
  secret      = google_secret_manager_secret.root_password_secret.id
  secret_data = random_password.root_password.result
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 BDD User password
# ----------------------------------------------------------------------------------------------------------------------

resource "random_password" "user_password" {
  length  = 16
  special = true
}

resource "google_secret_manager_secret" "user_password_secret" {
  secret_id = "${var.project_name}-sql-user-password"
  project   = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = {
    env = var.env
  }
}

resource "google_secret_manager_secret_version" "user_password_version" {
  secret      = google_secret_manager_secret.user_password_secret.id
  secret_data = random_password.user_password.result
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Cloud SQL
# ----------------------------------------------------------------------------------------------------------------------

resource "google_sql_database_instance" "datastats_sql" {
  depends_on = [ google_service_networking_connection.private_vpc_connection ]

  name                = "${var.project_name}-sql"
  region              = var.region
  project             = var.project_id
  database_version    = var.cloud_sql_version
  root_password       = random_password.root_password.result
  deletion_protection = false

  settings {
    tier                        = "db-f1-micro"
    edition                     = "ENTERPRISE"
    availability_type           = "ZONAL"
    deletion_protection_enabled = false
    disk_autoresize             = false
    disk_type                   = "PD_SSD"
    disk_size                   = 10
    user_labels                 = { "env" = var.env }

    ip_configuration {
      ipv4_enabled                                  = false
      enable_private_path_for_google_cloud_services = true
      private_network                               = google_compute_network.datastats_network.self_link
      ssl_mode                                      = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"
    }
  }
}

resource "google_sql_database" "datastats_bdd" {
  project  = var.project_id
  name     = "${var.project_name}-bdd"
  instance = google_sql_database_instance.datastats_sql.name
  charset  = "utf8"
}

resource "google_sql_user" "datastats_user" {
  project  = var.project_id
  name     = "${var.project_name}-user"
  instance = google_sql_database_instance.datastats_sql.name
  password = random_password.user_password.result
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 SQL SSL Cert
# ----------------------------------------------------------------------------------------------------------------------

resource "google_sql_ssl_cert" "datastats_client_cert" {
  project     = var.project_id
  common_name = "${var.project_name}-sql-client-cert"
  instance    = google_sql_database_instance.datastats_sql.name
}

# Secret to store SQL SSL Private Key
resource "google_secret_manager_secret" "ssl_private_key" {
  secret_id = "${var.project_name}-sql-ssl-private-key"
  project   = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = {
    env = var.env
  }
}

resource "google_secret_manager_secret_version" "ssl_private_key_version" {
  secret      = google_secret_manager_secret.ssl_private_key.id
  secret_data = google_sql_ssl_cert.datastats_client_cert.private_key
}

# Secret to store SQL SSL Server CA Cert
resource "google_secret_manager_secret" "ssl_server_ca_cert" {
  secret_id = "${var.project_name}-sql-ssl-server-ca-cert"
  project   = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = {
    env = var.env
  }
}

resource "google_secret_manager_secret_version" "ssl_server_ca_cert_version" {
  secret      = google_secret_manager_secret.ssl_server_ca_cert.id
  secret_data = google_sql_ssl_cert.datastats_client_cert.server_ca_cert
}

# Secret to store SQL SSL Cert
resource "google_secret_manager_secret" "ssl_cert" {
  secret_id = "${var.project_name}-sql-ssl-cert"
  project   = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = {
    env = var.env
  }
}

resource "google_secret_manager_secret_version" "ssl_cert_version" {
  secret      = google_secret_manager_secret.ssl_cert.id
  secret_data = google_sql_ssl_cert.datastats_client_cert.cert
}