variable "enable_config_recorder" {
  description = "Determines whether an AWS Config recorder, delivery bucket and role are created. Set to `true` only when the region has no recorder yet"
  type        = bool
  default     = false
}
