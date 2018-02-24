require('babel-register');
require('babel-polyfill');

module.exports = {
  migrations_directory: "./migrations",
  networks: {
    development: {
      host: "localhost",
      port: 9545,
      gas: 5000000,
      network_id: "*" // Match any network id
    }
  }
};
