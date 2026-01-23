data "azurerm_resource_group" "main" {
  name = var.resource_group
}

resource "random_password" "password" {
  length = 32
  special = true
  override_special = "_%@"
}


# This creates a MySQL server
resource "azurerm_mysql_flexible_server" "main" {
  name                = "${data.azurerm_resource_group.main.name}-mysql-flexible"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  administrator_login    = "petclinic"
  administrator_password = random_password.password.result

  sku_name = "B_Standard_B1ms"
  version  = "8.0.21"

  storage {
    size_gb           = 20
    auto_grow_enabled = true
  }
  backup_retention_days     = 7
  geo_redundant_backup_enabled = false


  tags = {
    Terraform = "true"
  }
}

# Base de datos en Flexible Server
resource "azurerm_mysql_flexible_database" "main" {
  name      = "${data.azurerm_resource_group.main.name}_mysql_db"
  resource_group_name = data.azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset   = "utf8"
  collation = "utf8_unicode_ci"
}


# This rule is to enable the 'Allow access to Azure services' checkbox
resource "azurerm_mysql_flexible_server_firewall_rule" "main" {
  name      = "${data.azurerm_resource_group.main.name}-mysql-firewall"
  resource_group_name = data.azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}


# This creates the plan that the service use
resource "azurerm_service_plan" "main" {
  name                = "${var.application_name}-plan"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "main" {
  name                = var.application_name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true

  site_config {
    always_on    = true
    java_version = "8"
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "SPRING_PROFILES_ACTIVE"              = "mysql"
    "SPRING_DATASOURCE_URL"               = "jdbc:mysql://${azurerm_mysql_flexible_server.main.fqdn}:3306/${azurerm_mysql_flexible_database.main.name}?useUnicode=true&characterEncoding=utf8&useSSL=true&useLegacyDatetimeCode=false&serverTimezone=UTC"
    "SPRING_DATASOURCE_USERNAME"          = "${azurerm_mysql_flexible_server.main.administrator_login}@${azurerm_mysql_flexible_server.main.name}"
    "SPRING_DATASOURCE_PASSWORD"          = azurerm_mysql_flexible_server.main.administrator_password
  }
}

resource "azurerm_linux_web_app_slot" "staging" {
  name                = "staging"
  app_service_id      = azurerm_linux_web_app.main.id
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on    = true
    java_version = "8"
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "SPRING_PROFILES_ACTIVE"              = "mysql"
    "SPRING_DATASOURCE_URL"               = "jdbc:mysql://${azurerm_mysql_flexible_server.main.fqdn}:3306/${azurerm_mysql_flexible_database.main.name}?useUnicode=true&characterEncoding=utf8&useSSL=true&useLegacyDatetimeCode=false&serverTimezone=UTC"
    "SPRING_DATASOURCE_USERNAME"          = "${azurerm_mysql_flexible_server.main.administrator_login}@${azurerm_mysql_flexible_server.main.name}"
    "SPRING_DATASOURCE_PASSWORD"          = azurerm_mysql_flexible_server.main.administrator_password
  }
}
