package main

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"fmt"
	"golang.org/x/crypto/ssh"
	"log"
	"net"
)

func main() {
	config := &ssh.ServerConfig{
		MaxAuthTries: -1,
		PasswordCallback: func(c ssh.ConnMetadata, pass []byte) (*ssh.Permissions, error) {
			return nil, fmt.Errorf("password rejected for %q", c.User())
		},
		KeyboardInteractiveCallback: func(c ssh.ConnMetadata, client ssh.KeyboardInteractiveChallenge) (*ssh.Permissions, error) {
			return nil, fmt.Errorf("keyboard-interactive rejected for %q", c.User())
		},
		PublicKeyCallback: func(c ssh.ConnMetadata, key ssh.PublicKey) (*ssh.Permissions, error) {
			return nil, fmt.Errorf("public key rejected for %q", c.User())
		},
	}
	private, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		log.Fatalf("ecdsa.GenerateKey: %s", err)
	}
	signer, err := ssh.NewSignerFromKey(private)
	if err != nil {
		log.Fatalf("ssh.NewSignerFromKey: %s", err)
	}
	config.AddHostKey(signer)

	listener, err := net.Listen("tcp", "0.0.0.0:22")
	if err != nil {
		log.Fatal("failed to listen for connection: ", err)
	}
	for {
		nConn, err := listener.Accept()
		if err != nil {
			log.Printf("failed to accept incoming connection: %v", err)
			continue
		}

		conn, _, _, err := ssh.NewServerConn(nConn, config)
		if err != nil {
			log.Printf("failed to handshake: %v", err)
			_ = nConn.Close()
			continue
		}
		log.Printf("Handshake succeeded with user %s", conn.User())
		err = conn.Close()
		if err != nil {
			return
		}
	}
}
