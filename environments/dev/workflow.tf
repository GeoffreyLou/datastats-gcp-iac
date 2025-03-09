
resource "google_service_account" "workflow_sa" {
  project      = var.project_id
  account_id   = "${var.project_name}-workflows-sa"
  display_name = "Workflows Service Account"
}

resource "google_project_iam_member" "workflow_sa_roles" {
  for_each = toset([
    "roles/vpcaccess.admin",
    "roles/vpcaccess.viewer",
    "roles/compute.networkAdmin",
    "roles/cloudbuild.builds.editor",
    "roles/iam.serviceAccountUser"
  ])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.workflow_sa.email}"
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Urls scrapper workflow
# ----------------------------------------------------------------------------------------------------------------------

resource "google_workflows_workflow" "urls_scrapper_workflow" {
  depends_on = [ google_service_account.workflow_sa ]

  name            = var.urls_scrapper_workflow_name
  project         = var.project_id
  region          = var.region
  description     = "Workflow used to generate resources for Cloud Run and trigger the Urls Scrapper Cloud Run Job"
  service_account = google_service_account.workflow_sa.id

  deletion_protection = false # set to "true" in production

  labels = {
    env = var.env
  }

  source_contents = <<EOF
    main:
      steps:
        - create_router:
            call: http.post
            args:
              url: "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/regions/${var.region}/routers"
              auth:
                type: OAuth2
              body:
                bgp:
                  advertiseMode: "DEFAULT"
                description: "Router for Nat x Datastats Cloud Runs"
                encryptedInterconnectRouter: true
                kind: "compute#router"
                name: ${var.project_name}-router
                network: ${google_compute_network.datastats_network.self_link}
                region: projects/${var.project_id}/regions/${var.region}
            next: wait_for_router

        - wait_for_router:
            call: sys.sleep
            args:
              seconds: 30
            next: create_nat

        - create_nat:
            call: gcloud
            args:
              args: "compute routers nats create ${var.project_name}-nat --router=${var.project_name}-router --region=${var.region} --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges"
            next: create_vpc_connector

        - create_vpc_connector:
            call: http.post
            args:
              url: "https://vpcaccess.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/connectors?connectorId=${var.serverless_connector_name}"
              auth:
                type: OAuth2
              body:
                network: ${google_compute_network.datastats_network.name}
                ipCidrRange: "10.10.0.0/28"
                minInstances: 2
                maxInstances: 10
                machineType: e2-micro

    gcloud:
      params: [args]
      steps:
      - create_build:
          call: googleapis.cloudbuild.v1.projects.builds.create
          args:
            projectId: ${var.project_id}
            parent: projects/${var.project_id}/locations/global
            body:
              serviceAccount: $${sys.get_env("GOOGLE_CLOUD_SERVICE_ACCOUNT_NAME")}
              options:
                logging: CLOUD_LOGGING_ONLY
              steps:
              - name: gcr.io/google.com/cloudsdktool/cloud-sdk
                entrypoint: /bin/bash
                args: $${["-c", "gcloud " + args + " > $$BUILDER_OUTPUT/output"]}
          result: result_builds_create
      - return_build_result:
          return: $${text.split(text.decode(base64.decode(result_builds_create.metadata.build.results.buildStepOutputs[0])), "\n")}
    EOF
}
