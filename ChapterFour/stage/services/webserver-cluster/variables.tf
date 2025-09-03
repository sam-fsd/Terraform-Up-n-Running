variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080  # Non-standard port to avoid conflicts
}