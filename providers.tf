provider "aws" {
  region = "us-east-1"
}

provider "vercel" {
  # Vercel API Token is sourced from VERCEL_API_TOKEN env var
}
