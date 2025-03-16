# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Context
# ----------------------------------------------------------------------------------------------------------------------

/*
  The workflow is used to avoid costs :
  - Cloud Composer is too expensive for this use case
  - Cloud NAT generate costs because Cloud Run Job lose internet access when connected to a Serverless VPC Connector
  - Serverless VPC Connector is expensive for this use case

  The workflow is used to create and delete resources for Cloud Run and trigger the Urls Scrapper Cloud Run Job

  TODO : change gcloud commands to use http requests or RPC API to generate more executions in free tier.
*/

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Service account and roles
# ----------------------------------------------------------------------------------------------------------------------

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
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter",
    "roles/run.developer",
    "roles/storage.objectViewer"
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
  call_log_level  = "LOG_ALL_CALLS"

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
            name: ${var.router_name}
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
          args: "compute routers nats create ${var.nat_name} --router=${var.project_name}-router --region=${var.region} --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges"
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
            maxInstances: 3
            machineType: e2-micro
        next: wait_for_vpc_connector

    - wait_for_vpc_connector:
        call: sys.sleep
        args:
          seconds: 120
        next: update_cloud_run_job

    - update_cloud_run_job:
        call: gcloud
        args:
          args: "run jobs update ${module.run_job_urls_scrapper.cloud_run_job_name} --region=${var.region} --vpc-connector=${var.serverless_connector_name}"
        next: get_json_from_bucket

    - get_json_from_bucket:
        call: googleapis.storage.v1.objects.get
        args:
          bucket: ${module.utils_bucket.name}
          object: ${google_storage_bucket_object.default_jobs_list.name}
          alt: media
        result: object_data

    - iterate_on_jobs:
        for:
          value: job_extracted
          in: $${object_data.jobs_to_scrap}
          steps:
            - assign_var:
                assign:
                  - job: $${job_extracted}
                next: trigger_cloud_run_job
            - trigger_cloud_run_job:
                call: googleapis.run.v1.namespaces.jobs.run
                args:
                  name: namespaces/${var.project_id}/jobs/${module.run_job_urls_scrapper.cloud_run_job_name}
                  location: ${var.region}
                  body:
                    overrides:
                        containerOverrides:
                            env:
                                - name: JOB_TO_SCRAP
                                  value: $${job}
        next: let_last_job_finish

    - let_last_job_finish:
        call: sys.sleep
        args:
          seconds: 30
        next: remove_vpc_connector

    - remove_vpc_connector:
        call: gcloud
        args:
          args: "run jobs update ${module.run_job_urls_scrapper.cloud_run_job_name} --region=${var.region} --clear-vpc-connector"
        next: delete_nat

    - delete_nat:
        call: gcloud
        args:
          args: "compute routers nats delete ${var.nat_name} --router=${var.router_name} --region=${var.region}"
        next: delete_router

    - delete_router:
        call: gcloud
        args:
          args: "compute routers delete ${var.router_name} --region=${var.region}"
        next: delete_vpc_connector

    - delete_vpc_connector:
        call: gcloud
        args:
          args: "compute networks vpc-access connectors delete ${var.serverless_connector_name} --region=${var.region} --quiet"

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
