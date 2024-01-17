# UNIAdaptive Installation Scripts

This repository contains the necessary files to set up and run UNIAdaptive.

## Files

1. `docker-compose.yml`: This file contains the configuration for the front, back, and db services.
2. `configureTools.sh`: This script is used to configure the Front End and Back End.

## How to Run

1. Clone this repository.
2. Run the `configureTools.sh` script to configure the Front End and Back End.
3. Use Docker Compose to start the services. Use the command `docker-compose up`.

If you want to reuse an existing database, you can start only the front and back services. Use the command `docker-compose up front back`.

## Additional Information

Front End Repository: [uniadaptiveLTI-Front](https://github.com/uniadaptiveLTI/uniadaptiveLTI-Front)

Back End Repository: [uniadaptiveLTI-Back](https://github.com/uniadaptiveLTI/uniadaptiveLTI-Back)
