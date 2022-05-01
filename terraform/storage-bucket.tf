terraform {
  
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "Terraform-2_test"
    region     = "ru-central1"
    key        = "terraform..tfstate"
    access_key = "ckfjmrrcodkerf94k58"
    secret_key = "f934kf93kd055flce"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "yandex" {
  service_account_key_file     = "<OAuth или статический ключ сервисного аккаунта>"
  cloud_id  = "b1gtab6f64ej3q1jlgut"
  folder_id = "b1gab7pfm9o4ct34hq7e"
  zone      = "ru-central1-a"
}
