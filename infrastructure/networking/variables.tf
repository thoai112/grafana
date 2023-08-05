
variable "secondary_region"{
    default="us-east-2"
}

variable "primary_region"{
    default="us-east-1"
}



# restrict access to your IP
variable "access_ip"{
    default="0.0.0.0/0"
}