module "wrapper" {
  source = "../../modules/framework"

  for_each = var.items

  controls    = try(each.value.controls, var.defaults.controls)
  create      = try(each.value.create, var.defaults.create, true)
  description = try(each.value.description, var.defaults.description, null)
  name        = try(each.value.name, var.defaults.name)
  region      = try(each.value.region, var.defaults.region, null)
  tags        = try(each.value.tags, var.defaults.tags, {})
  timeouts    = try(each.value.timeouts, var.defaults.timeouts, {})
}
