#!/usr/bin/env python3
import argparse
import collections
import logging
import pathlib
import re
import requests
import sys
import typing

import yaml


def fetch_erlang_tags() -> typing.Iterable[str]:
    """
    Fetch all tags available on the official erlang docker image on DockerHub.
    """
    url: str | None = (
        "https://hub.docker.com/v2/repositories/library/erlang/tags?page_size=100"
    )
    while url is not None:
        r = requests.get(url)
        data = r.json()
        yield from (tag["name"] for tag in data["results"])
        url = data.get("next")


def fetch_ssh_versions() -> dict[str, list[str]]:
    """
    Fetch a dict of Erlang SSH versions and their corresponding OTP versions.

    The Erlang/OTP version is not the same as the ssh Application version. For
    example, Erlang/OTP 25.1.2 ships with ssh-4.15, so we need to set the
    version accordingly.

    The versions are documented at in the `otp_versions.table` file in
    the erlang/otp git repository:

    - <https://raw.githubusercontent.com/erlang/otp/master/otp_versions.table>
    """

    versions: dict[str, list[str]] = collections.defaultdict(list)
    r = requests.get(
        " https://raw.githubusercontent.com/erlang/otp/master/otp_versions.table"
    )
    for line in r.text.splitlines():
        matchobj = re.match(
            r"^OTP-(?P<otp>[\d\.]+)\s*:\s*.*ssh-(?P<ssh>[\d\.]+).*$", line
        )
        assert matchobj is not None
        otp_version = matchobj.group("otp")
        ssh_version = matchobj.group("ssh")
        versions[ssh_version].append(otp_version)
    return versions


def numeric_version(version: str) -> tuple[int, ...]:
    """Turn a dot-separated numeric version string into a tuple of ints."""
    return tuple(int(component) for component in version.split("."))


def find_versions_with_tag() -> typing.Iterable[tuple[str, str, str]]:
    """
    For each SSH version, find a OTP version and DockerHub tag.
    """
    logger = logging.getLogger(__name__)

    logger.info("Fetching available tags from docker.io...")
    available_tags = set(fetch_erlang_tags())
    logger.info("Available tag count: %d", len(available_tags))
    logger.debug("Available tags: %r", available_tags)

    logger.info("Fetching Erlang SSH versions from GitHub...")
    ssh_versions = fetch_ssh_versions()
    logger.info("SSH version  count: %d", len(ssh_versions))
    logger.debug("SSH versions: %r", ssh_versions)

    for ssh_version, otp_versions in ssh_versions.items():
        tag = None
        for otp_version in sorted(
            otp_versions,
            key=numeric_version,
            reverse=True,
        ):
            for tag_candidiate in (
                f"{otp_version}.0.0-alpine",
                f"{otp_version}.0.0",
                f"{otp_version}.0-alpine",
                f"{otp_version}.0",
                f"{otp_version}-alpine",
                otp_version,
            ):
                if tag_candidiate in available_tags:
                    tag = tag_candidiate
                    break
            if tag is not None:
                break
        else:
            logger.warning("Failed to find tag for version %s", ssh_version)
            logger.debug(
                "SSH %s is available in the following OTP versions: %r",
                ssh_version,
                otp_versions,
            )
            continue

        assert tag is not None
        assert otp_version is not None
        yield ssh_version, otp_version, tag


def main(argv: list[str] | None = None) -> int:
    """
    Main Method.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-v",
        "--verbose",
        help="Show debug output",
        action="store_const",
        const=logging.DEBUG,
        default=logging.INFO,
        dest="loglevel",
    )
    parser.add_argument(
        "-o",
        "--output-file",
        type=argparse.FileType("w"),
        required=True,
    )
    args = parser.parse_args(argv)

    logging.basicConfig(level=args.loglevel, format="%(message)s")

    yaml_data = {
        "version": "3.2",
        "services": {},
    }
    for ssh_version, otp_version, tag in sorted(
        find_versions_with_tag(), key=lambda x: numeric_version(x[0])
    ):
        logging.info("Erlang SSH %s available in tag '%s'", ssh_version, tag)
        service_name = f"erlang-ssh-server-{ssh_version}"
        build_data = {"context": "."}
        if not tag.endswith("-alpine"):
            build_data["dockerfile"] = "Dockerfile.debian"
        build_data.update(
            {
                "target": "erlang-ssh-server",
                "args": {
                    "VERSION": otp_version,
                },
            }.items()
        )
        yaml_data["services"][service_name] = {
            "image": f"rub-nds/erlang-ssh-server:{ssh_version}",
            "build": build_data,
        }
    yaml.dump(yaml_data, args.output_file, default_flow_style=False, sort_keys=False)

    return 0


if __name__ == "__main__":
    sys.exit(main())
