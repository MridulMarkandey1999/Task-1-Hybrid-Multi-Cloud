provider "kubernetes" {
  config_context_cluster   = "minikube"
}


resource "kubernetes_pod" "mypod1" {
  metadata {
    name = "mywebpod"
  }

  spec {
    container {
      image = "vimal13/apache-webserver-php"
      name  = "mywebcontainer"
        }
  }
}