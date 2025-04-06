variable "project_id" {
  description = "The project ID to host the cluster in"
  type        = string
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name for the GKE cluster"
  type        = string
  default     = "vulnerable-gke-cluster"
}

variable "node_pool_name" {
  description = "The name for the vulnerable node pool"
  type        = string
  default     = "vulnerable-node-pool"
}

variable "machine_type" {
  description = "The machine type for the GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "initial_node_count" {
  description = "The initial number of nodes for the node pool"
  type        = number
  default     = 1
}

# Define the GKE cluster
resource "google_container_cluster" "vulnerable_cluster" {
  project                  = var.project_id
  name                     = var.cluster_name
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = 1 # Required even if remove_default_node_pool is true

  # Enable security posture scanning to detect the vulnerability
  security_posture_config {
    mode                  = "BASIC"
    vulnerability_mode    = "VULNERABILITY_BASIC"
  }

  # Basic configuration, adjust as needed
  networking_mode = "VPC_NATIVE"

  release_channel {
    channel = "UNSPECIFIED" # Avoid automatic upgrades that might fix the vulnerability
  }

  # Ensure network and subnetwork are configured or created separately
  # network    = "your-vpc-network-name"
  # subnetwork = "your-gke-subnetwork-name"

  # Example: using default network
  network    = "default"
  subnetwork = "default" # Assumes default subnetwork exists in the region
}

# Define the vulnerable node pool using an older COS image version
resource "google_container_node_pool" "vulnerable_node_pool" {
  project    = var.project_id
  name       = var.node_pool_name
  location   = var.region
  cluster    = google_container_cluster.vulnerable_cluster.name
  node_count = var.initial_node_count

  management {
    auto_repair  = true
    auto_upgrade = false # Prevent automatic upgrades that would fix the vulnerability
  }

  node_config {
    machine_type = var.machine_type
    image_type   = "COS_CONTAINERD" # Use Container-Optimized OS

    # Specify a vulnerable GKE version (older than 1.31.6-gke.1064000)
    # Note: This specific version might not always be available.
    # If apply fails, you might need to find another available version
    # in the 1.31 range or slightly older known to have the vulnerability.
    # You can list available versions with:
    # gcloud container get-server-config --region <region> --project <project_id>
    # Look for versions in the 1.31.x line before 1.31.6-gke.1064000
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  # Explicitly set the version for the node pool
  version = "1.31.4-gke.1372000"
}

# Outputs (optional)
output "cluster_endpoint" {
  value = google_container_cluster.vulnerable_cluster.endpoint
}

output "cluster_ca_certificate" {
  value     = google_container_cluster.vulnerable_cluster.master_auth[0].cluster_ca_certificate
  sensitive = true
}

output "node_pool_version" {
  value = google_container_node_pool.vulnerable_node_pool.version
} 
