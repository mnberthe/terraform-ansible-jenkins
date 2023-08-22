terraform {
  cloud {
    organization = "mtc-terransible-ber"

    workspaces {
      name = "terransible"
    }
  }
}