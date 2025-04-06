provider "google" {
  # Credentials will be automatically sourced from the environment
  # (e.g., gcloud auth application-default login)
}

module "vulnerable_gke_test" {
  source     = "./modules/gke"
  project_id = "cpt-poc-1"

  # You can override other variables defined in modules/gke/vulnerable_cluster.tf here if needed
  # region       = "us-west1" 
  # cluster_name = "my-test-cluster"
}

output "test_cluster_endpoint" {
  description = "Endpoint for the test GKE cluster"
  value       = module.vulnerable_gke_test.cluster_endpoint
}

output "test_node_pool_version" {
  description = "Version of the vulnerable node pool"
  value       = module.vulnerable_gke_test.node_pool_version
} 
