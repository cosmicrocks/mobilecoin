# Environment Variables: How to Configure Your Node

The following environment variables should be provided:

| Variable                | Value              | Function                                                                                                                                                                                                                                                                      |
| ----------------------- | ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `LOCAL_NODE_ID`         | address:port       | Local node name for logging. Should ideally match the value of `peer-responder-id` as provided to consensus-service.                                                                                                                                                          |
| `NODE_LEDGER_DIR`       | Path to ledger     | The location of the ledger. We suggest that this should be persistently stored outside the container and mounted in. On startup, if the contents of `NODE_LEDGER_DIR` are empty, then the origin block from within the container should be copied into the `NODE_LEDGER_DIR`. |
| `CONSENSUS_ADMIN_URI`   | URI                | The URI for the admin http service which provides a management panel to the consensus service. The gateway is started in the container and is set to listen via this environment variable. Used by mc-admin-http-gateway.                                                     |
| `AWS_ACCESS_KEY_ID`     | AWS Credential     | Should have write access to your S3 ledger archive bucket. Used by ledger-distribution.                                                                                                                                                                                       |
| `AWS_SECRET_ACCESS_KEY` | AWS Credential     | Should have write access to your S3 ledger archive bucket. Used by ledger-distribution.                                                                                                                                                                                       |
| `AWS_PATH`              | S3 URL             | The S3 location of your S3 ledger archive bucket. Used by ledger-distribution.                                                                                                                                                                                                |
| `SGX_MODE`              | HW or SW           | Indicates whether to run with SGX in hardware or simulation mode. (Should be HW). Used by consensus-service.                                                                                                                                                                  |
| `IAS_MODE`              | PROD or DEV        | Indicates whether to hit the Intel Attestation Service’s prod or dev endpoint. (Should be PROD). Used by consensus-service.                                                                                                                                                   |
| `RUST_LOG`              | info, debug, trace | Sets the log level. Can also be tuned per specific rust crate. See env\_logger. Used by ledger-distribution and consensus-service.                                                                                                                                            |
| `RUST_BACKTRACE`        | full, 1, 0         | Indicates how much detail to provide in the backtrace in the event of a panic. Used by ledger-distribution and consensus-service.                                                                                                                                             |