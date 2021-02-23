variable "project" {default = "auto-assign-bot"}
variable "project_id" {default = "diagvn"}
variable "region" {default = "asia-southeast1"}
variable "env" {default = "prod"}

variable "APP_ID" { default = "101848" }
variable "WEBHOOK_SECRET" { default="development" }
variable "LOG_LEVEL" { default="debug" }
variable "WEBHOOK_PROXY_URL" { default="https://auto-assign-bot.diag.vn" }
variable "PRIVATE_KEY_PATH" { default="/app/id_rsa" }
