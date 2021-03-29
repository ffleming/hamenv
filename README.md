# dmr-bridge
Infrastructure deployment for ham radio tools.

## What is this?

This is a Docker container that bridges a USRP client to the BrandMeister DMR
network. It allows you to use a USRP client like [DVSwitch's USRP_Client](https://github.com/DVSwitch/USRP_Client)
to run netops on BrandMeister. It uses the following:

* [Analog Bridge](https://github.com/DVSwitch/Analog_Bridge)
* [MMDVM Bridge](https://github.com/DVSwitch/MMDVM_Bridge)

dmr-bridge was forked from [hsoj's hamenv](https://github.com/hsoj/hamenv). It was
changed in the following ways (among others):

* Removed support for emulated MD380 decoding
* Added (required) support for a [ThumbDV](http://nwdigitalradio.com/product/thumbdv/)
(or similar) hardware AMBE3000 decoder
* Consolidated into a single container
* Removed much of the configuration that doesn't matter to the final
  functionality including:
* Fixed some bugs

## Usage

For easy setup, you can use `scripts/build_and_run.sh`. Otherwise, the
container uses the following environment variables:

| Item                          | Environment Variable | Required? | Default                          |
|-------------------------------|----------------------|-----------|----------------------------------|
| Callsign                      | `CALLSIGN`           | Yes       | n/a                              |
| DMR ID                        | `DMR_ID`             | Yes       | n/a                              |
| BrandMeister hotspot password | `BM_PASSWD`          | Yes       | n/a                              |
| USRP Port                     | `USRP_PORT`          | Yes       | n/a                              |
| DMR repeater                  | `REPEATER_ID`        | No        | `${CALLSIGN}01`                  |
| Latitude                      | `LATITUDE`           | No        | 0                                |
| Longitude                     | `LONGITUDE`          | No        | 0                                |
| Location                      | `LOCATION`           | No        | Unknown                          |
| Description                   | `DESCRIPTION`        | No        | netops using ffleming/dmr-bridge |
| BrandMeister address          | `BM_ADDR`            | No        | 3103.repeater.net                |
| BrandMeister port             | `BM_PORT`            | No        | 62031                            |
| BrandMeister local port       | `BM_LOCAL_PORT`      | No        | 62032                            |
| URL                           | `URL`                | No        | `https://qrz.com/db/${CALLSIGN}` |

Your DMR ID is available at [radioid.net](https://radioid.net).

If you need to set a hotspot password, do so at the [BrandMeister self-care page](https://brandmeister.network/?page=selfcare).

## Client

I maintain a [fork of DVSwitch's USRP_Client](https://github.com/ffleming/USRP_Client)
that allows devices that are both input and output (like audio interfaces) to
function. I plan to remove that fork when the relevant patch hits the upstream.
