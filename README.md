# Finding SSH Strict Key Exchange Violations by State Learning - Artifacts

This repository contains the artifacts for the paper "Finding SSH Strict Key
Exchange Violations by State Learning", accepted at the ACM Conference on
Computer and Communications Security (CCS) 2025.

## Prerequisites

### Hardware Requirements

We recommend running these artifacts on a machine with at least 8 CPU cores
available. Running the artifacts on a machine with fewer CPU cores available
may slow down learning times and can cause unexpected results.

Our experiments were conducted on a desktop computer with an Intel i9-12900KF
16-core processor and 64 GB of RAM.

### Software Requirements

- An operating system with the `bash` shell installed (e.g., Ubuntu 24.04).
  Required for running the experiments only, the artifacts itself are platform
  independent through the use of Docker images. We used GNU bash version 5.2.21.
- Docker 28.3.3 or newer. Refer to the official [Docker Docs](https://docs.docker.com/engine/install/)
  for installation instructions.

### Basic Functionality Test

First, run `scripts/00_build_images.sh` to build all required Docker images.
Afterward, verify that the `ssh-state-learner:latest` image is available and
ready to use. Running the following command should output the CLI reference
of the SSH-State-Learner to stdout:

```bash
docker run --rm ssh-state-learner:latest --help
```

## Claims

The following major claims are made with regard to the artifacts:

1. The `ssh_state_learner` tool (`code/ssh_state_learner`) is capable of
   extracting the state machine of SSH server implementations with strict kex
   enabled by state learning. In particular, it can be used to learn state
   machines similar to the ones given in `data/state_machines` and Table 5 in
   the paper.
2. The violations described in Section 4.2 and Table 2 in the paper are accurate
   and can be verified by a proof-of-concept protocol flow.
3. Erlang SSH 5.2.8 (Erlang/OTP version 27.3.0.0) is vulnerable to
   [CVE-2025-32433](https://www.cve.org/CVERecord?id=CVE-2025-32433), an
   unauthenticated remote code execution vulnerability, described in Section 4.4
   in the paper.

> [!TIP]
> Each claim can be proven by the corresponding experiment with the same number,
> that is, claim 1 can be proven by E1, claim 2 by E2, and so on.

> [!NOTE]
> The vendor of Tectia SSH only offers the most recent version for download,
> which already contains a fix for the vulnerability described in Section 4.3.
> Due to licensing restrictions, we cannot include the older version of Tectia
> SSH either. Therefore, we do not include a claim similar to claim 3 for this
> vulnerability.

## Experiments

For running the artifacts, you can use the provided scripts in the `scripts/`
directory. Each script is designed to perform a single experiment.

> [!IMPORTANT]
> Before running any experiment, make sure to build all required Docker images
> by running `scripts/00_build_images.sh`.

### E1 - Learning SSH Server State Machines

> [!NOTE]
> - Estimated time required: up to 1 hour / implementation and KEX flow type
> - Proves claim: C1 via comparison between the results in `results` and `data/state_machines`

To learn the state machine of an SSH server implementation, run `scripts/01_learn_ssh_impl.sh`.
You will be asked to select an SSH implementation as well as a KEX flow type for
learning. The script supports all variants listed in Table 2 in the paper.

Afterward, the script will start 16 instances of the target SSH server
for learning and bind them to ports 30020-30035 on localhost. For Bitvise SSH,
Lancom LCOS and Tectia SSH manual installation steps are required. Follow
the script's instruction and provide the server's address and port when asked.

By default, the learner will be invoked with a timeout of 1 hour to avoid
excessive learning times, similar to the results indicated in Table 5 in the paper.
The resulting state machine, including all intermediate hypotheses, can be found
in `results/<implementation>/<kex flow type>`.

If desired, the `ssh-state-learner:latest` image can be used directly to learn
other targets or to tweak the options given to the state learner. Run
`docker run --rm ssh-state-learner:latest --help` to learn about all supported
flags and options. You may also refer to the `learn_ssh_impl` function in the
evaluation script to learn more about how to use the state learner. Please note,
that this is not required to prove claim C1.

### E2 - Testing Strict KEX Violations

> [!NOTE]
> - Estimated time required: 3 minutes / violation
> - Proves claim: C2 by successful execution of proof-of-concept protocol flows

Run `scripts/02_test_strict_kex_violation.sh`. You will be asked to select one
of the violations given in Table 2 in the paper. With the violation selected,
the script will start an SSH protocol flow that violates strict kex with the
corresponding SSH server (similar to E1, manual interaction is required for
Lancom LCOS and Tectia SSH). You may inspect the printed workflow trace file to
learn about which messages are sent and received.

All proof-of-concept workflows conclude with receiving the `SSH_MSG_SERVICE_ACCEPT`
message from the server, which is sent inside the secure channel after the key
exchange is finished. Receiving this message is equivalent to the fact that
the SSH server accepted the violating protocol flow during key exchange. The
custom SSH clients used for execution will check whether the workflow trace
was executed as planned and will output success or failure to stdout.

### E3 - Unauthenticated Remote Code Execution in Erlang SSH (CVE-2025-32433)

> [!NOTE]
> - Estimated time required: 5 minutes
> - Proves claim: C3 by successful execution of the proof-of-concept protocol flow

First, inspect the proof-of-concept protocol flow contained in `code/pocs/erlang_rce/erlang_early_channel_open.xml`.
Confirm that it resembles a protocol flow similar to the one in Figure 7 in the
paper. We use the client's default command for the `SSH_MSG_CHANNEL_REQUEST`
to reduce verbosity, which will trigger a syntax error when executed as Erlang
code. The error message will be contained in an `SSH_MSG_CHANNEL_EXTENDED_DATA`
message.

Run `scripts/03_run_erlang_rce_poc.sh`, which will spin up an Erlang SSH docker
container and execute the proof-of-concept workflow trace against it. Inspect
the output of the SSH client to confirm that the workflow trace was executed
as planned and that the payload of the `SSH_MSG_CHANNEL_EXTENDED_DATA` actually
contained a syntax error, indicative of a successful remote code execution.

## Repository Structure

```
.
├── code
│   ├── impl                            # Dockerfiles and docker-compose.yml files for SSH servers running on Linux
│   ├── pocs                            # Proof-of-concept workflow traces to use with the ssh_attacker client
│   │   ├── erlang_rce                  # PoC for the Erlang remote code execution vulnerability (CVE-2025-32433)
│   │   └── strict_kex_violations       # PoCs for the strict kex violations given in Table 2 in the paper
│   ├── ssh_attacker                    # A highly modifiable SSH implementation written in Java that can be used as a library or directly as a client
│   └── ssh_state_learner               # The SSH state learner written in Kotlin based on ssh_attacker
├── data
│   └── state_machines                  # Results from our experimental evaluation
├── scripts
│   ├── 00_build_images.sh              # Script for setting up a fresh evaluation environment with all dependencies installed
│   ├── 01_learn_ssh_impl.sh            # Runs the key_scraper tool on GitHub, Gitlab, and Launchpad for 24 hours
│   ├── 02_test_strict_kex_violation.sh # Performs a full run of the evaluation pipeline on the keys collected by the key_scraper tool
│   └── 03_run_erlang_rce_poc.sh        # Generates test keys for testing public key upload restrictions
└── README.md
```
