"""
AWS Template Configuration. Still need to fill out all TODOs.
"""

from .config_default import *

# General Settings
SERVER_NAME = "TODO"
SECRET_KEY = "TODO"  # just a random string of characters and symbols about 30 characters long; can use `''.join(secrets.choice(string.digits+string.ascii_letters+string.punctuation) for _ in range(30))`` to generate
SECRET_KEY_ALT = "TODO"  # same as above, just different
PROXY_DEPTH = 1
PREFERRED_URL_SCHEME = "https"

# Database Server Settings
DATABASE_URL = "mongodb+srv://TODO.mongodb.net/?retryWrites=true&w=majority"

# Email Server Settings
SERVER_EMAIL = f"no-reply@{SERVER_NAME}"
CONTACT_RECIPIENT = f"contact@{SERVER_NAME}"

MAIL_DEFAULT_SENDER = SERVER_EMAIL  # make sure this is a verified email address in SES
MAIL_SERVER = "email-smtp.TODO.amazonaws.com"  # see https://docs.aws.amazon.com/general/latest/gr/ses.html; TODO is your region
MAIL_PORT = 587  # uses STARTTLS on this port
MAIL_USERNAME = "TODO"  # your SES SMTP username
MAIL_PASSWORD = "TODO"  # your SES SMTP password
MAIL_USE_TLS = True

# Celery settings
CELERY = {
    "broker_url": "redis://localhost",
    "result_backend": "redis://localhost",
}

# Image and File Storage Settings
S3_REGION = "TODO"
IMAGE_BUCKET = "TODO"
FILE_BUCKET = "TODO"
IMAGE_URL_BASE = f"https://{IMAGE_BUCKET}.s3.{S3_REGION}.amazonaws.com"
FILE_URL_BASE = f"https://{FILE_BUCKET}.s3.{S3_REGION}.amazonaws.com"

# Importer and Format Handler Binaries and Libraries
F3D_APP = "/usr/local/bin/f3d"
F3D_USE_XVFB = False
OPENSCAD_BIN = "/usr/local/bin/openscad"

# Importer and Format Handler API Keys Settings
THINGIVERSE_TOKEN = "TODO"  # the App Token from https://www.thingiverse.com/developers
MYMINIFACTORY_TOKEN = "TODO"  # from https://www.myminifactory.com/pages/for-developers, have to create an OAuth application then create and enable the API key
ONSHAPE_ACCESS_KEY = "TODO"  # from https://dev-portal.onshape.com/keys
ONSHAPE_SECRET_KEY = "TODO"
