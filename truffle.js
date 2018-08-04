require('babel-register');
require('babel-polyfill');

module.exports = {
    migrations_directory: "./migrations",
    networks: {
        development: {
            host: "localhost",
            port: 9545,
            network_id: "*",
            gas: 8000000
        },
        coverage: {
            host: "localhost",
            port: 8555,
            network_id: "*",
            gas: 0xffffffff,
            gasPrice: 0x01
        }
    },
    solc: {
        optimizer: {
            enabled: true,
            runs: 200
        }
    }
};
