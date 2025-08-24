#!/usr/bin/env python3
#
# Copyright (c) 2013-2017 by Ron Frederick <ronf@timeheart.net>.
# All rights reserved.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License v1.0 which accompanies this
# distribution and is available at:
#
#     http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#     Ron Frederick - initial implementation, API, and documentation

# To run this program, the file ``ssh_host_key`` must exist with an SSH
# private key in it to use as a server host key. An SSH host certificate
# can optionally be provided in the file ``ssh_host_key-cert.pub``.

import argparse
import asyncio, asyncssh, sys
import logging
import pathlib

PASSWORDS = {}
AUTHORIZED_KEYS_FILES = {}


async def handle_client(process):
    process.stdout.write("Enter numbers one per line, or EOF when done:\n")

    total = 0

    try:
        async for line in process.stdin:
            line = line.rstrip("\n")
            if line:
                try:
                    total += int(line)
                except ValueError:
                    process.stderr.write("Invalid number: %s\n" % line)
    except asyncssh.BreakReceived:  # pyright: ignore reportGeneralTypeIssues
        pass

    process.stdout.write("Total = %s\n" % total)
    process.exit(0)


class MySSHServer(asyncssh.SSHServer):  # pyright: ignore reportGeneralTypeIssues
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._logger = logging.getLogger(__name__)
        self._conn = None

    def connection_made(self, conn):
        self._conn = conn
        self._logger.info(
            "Connection established from %s", conn.get_extra_info("peername")[0]
        )

    def connection_lost(self, exc):
        if exc:
            self._logger.error("SSH connection error: %s", str(exc))
        else:
            self._logger.info("SSH connection closed.")

    def begin_auth(self, username):
        assert self._conn is not None

        try:
            authorized_keys_file = AUTHORIZED_KEYS_FILES[username]
        except KeyError:
            self._logger.debug("User %r has no authorized_keys file.", username)
            self._logger.debug(
                "Users with authorized_keys file: %r.",
                list(AUTHORIZED_KEYS_FILES.keys()),
            )
            pass
        else:
            self._logger.debug(
                "authorized_keys file for user %r: %s", username, authorized_keys_file
            )
            try:
                self._conn.set_authorized_keys(str(authorized_keys_file))
            except IOError:
                self._logger.exception(
                    "error occurred during begin_auth, maybe there is no key for this user."
                )
                self._logger.debug(
                    "Falling back to password authentication for user %r.", username
                )
                pass
        return True

    def password_auth_supported(self):
        # If there are no passwords, let's password-authentication will be
        # disabled.
        return bool(PASSWORDS)

    def validate_password(self, username, password):
        self._logger.debug("Validating password for user %r.", username)
        try:
            expected_password = PASSWORDS[username]
        except KeyError:
            self._logger.debug("User %r has no password.", username)
            self._logger.debug("Users with passwords: %r.", list(PASSWORDS.keys()))
        else:
            if password == expected_password:
                self._logger.debug("Password for user %r is correct.", username)
                return True

        self._logger.debug("Password authentication for user %r failed.", username)
        return False


def validate_username(text):
    stripped = text.strip()
    if not stripped:
        raise ValueError("Username must not be empty!")
    return stripped


async def start_server(port, host_keys):
    await asyncssh.create_server(  # pyright: ignore reportGeneralTypeIssues
        MySSHServer,
        "",
        port,
        server_host_keys=["ssh_host_key"],  # TODO make dynamic
        process_factory=handle_client,
    )


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("username", help="SSH username", type=validate_username)
    parser.add_argument(
        "-P",
        "--password",
        action="store",
        help="SSH password (password auth will be disabled if not specified)",
    )
    parser.add_argument(
        "-f",
        "--authorized-keys-file",
        type=pathlib.Path,
        action="store",
        help="SSH authorized_keys file (pubkey auth won't not work if not specified)",
    )
    parser.add_argument(
        "-p",
        "--port",
        action="store",
        type=int,
        default=22,
        help="SSH port to listen on",
    )
    parser.add_argument(
        "--host-key",
        action="store",
        type=pathlib.Path,
        default=pathlib.Path(__file__).parent.joinpath("ssh_host_key"),
        help="SSH host key",
    )
    args = parser.parse_args(argv)

    logging.basicConfig(level=logging.DEBUG)
    logger = logging.getLogger(__name__)

    logger.info("Username: %r", args.username)
    if args.password is not None:
        logger.info("Password: %r", args.password)
        PASSWORDS[args.username] = args.password
    else:
        logger.warning("No password given, password auth will be disabled.")

    if args.authorized_keys_file is not None:
        logger.info("authorized_keys file: %s", args.authorized_keys_file)
        AUTHORIZED_KEYS_FILES[args.username] = args.authorized_keys_file
    else:
        logger.warning("No authorized_keys file given, pubkey auth will not work.")

    if args.password is None and args.authorized_keys_file is None:
        logger.warning(
            "Neither password nor authorized_keys file specified, you won't be able to log in!"
        )

    logger.info("Server starting up on %d...", args.port)
    loop = asyncio.get_event_loop()
    try:
        loop.run_until_complete(start_server(port=args.port, host_keys=[args.host_key]))
    except (OSError, asyncssh.Error) as exc:  # pyright: ignore reportGeneralTypeIssues
        sys.exit("Error starting server: " + str(exc))
    loop.run_forever()
    return 0


if __name__ == "__main__":
    sys.exit(main())
