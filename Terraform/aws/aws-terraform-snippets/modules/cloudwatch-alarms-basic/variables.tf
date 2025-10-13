variable "name" { type = string }
variable "instance_id" { type = string }
variable "alarm_cpu_threshold" { type = number default = 70 }
variable "sns_topic_arn" { type = string }
