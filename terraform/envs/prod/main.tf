provider "aws" {
  region = var.region
}

module "network" {
  source              = "../../modules/network"
  env                 = var.env
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
}

module "security" {
  source = "../../modules/security"
  env    = var.env
  vpc_id = module.network.vpc_id
}

module "vm" {
  source        = "../../modules/vm"
  env           = var.env
  ami_id        = var.ami_id
  instance_type = var.instance_type
  subnet_id     = module.network.public_subnet_ids[0]
  sg_id         = module.security.sg_id
  key_name      = var.key_name
}
