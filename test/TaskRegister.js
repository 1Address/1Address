// @flow
'use strict'

const BigNumber = web3.BigNumber;
const expect = require('chai').expect;
const should = require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(web3.BigNumber))
    .should();

import ether from './helpers/ether';
import {advanceBlock} from './helpers/advanceToBlock';
import {increaseTimeTo, duration} from './helpers/increaseTime';
import latestTime from './helpers/latestTime';
import EVMThrow from './helpers/EVMThrow';

var EC = artifacts.require("./EC.sol");
var Token = artifacts.require("./VanityToken.sol");
var TaskRegister = artifacts.require("./TaskRegister.sol");

contract('TaskRegister', async function([_, wallet1, wallet2, wallet3]) {

    // PrivKey => PublicKey
    // c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3 => 0x627306090abab3a6e1400e9345bc60c78a8bef57
    // ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f => 0xf17f52151ebef6c7334fad080c5704d77216b732

    var ec;
    var token;
    var taskRegister;

    before(async function() {
        ec = await EC.new();
        token = await Token.new();
        taskRegister = await TaskRegister.new(ec.address, token.address, 0);
    });

    it("should", async function() {
        wallet1.should.be.equal("0xf17f52151ebef6c7334fad080c5704d77216b732");

        //
        // ./bitcoin-tool --input-type private-key --input-format hex --input c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3 --output-type public-key --output-format hex --network bitcoin --public-key-compression uncompressed
        //
        // 04
        // af80b90d25145da28c583359beb47b21796b2fe1a23c1511e443e7a64dfdb27d
        // 7434c380f0aa4c500e220aa1a9d068514b1ff4d5019e624e7ba1efe82b340a59
        //

        await taskRegister.createBitcoinAddressPrefixTask("1Anton", 0, "0xaf80b90d25145da28c583359beb47b21796b2fe1a23c1511e443e7a64dfdb27d", "0x7434c380f0aa4c500e220aa1a9d068514b1ff4d5019e624e7ba1efe82b340a59");

        //
        // $ ./vanitygen         -P 04af80b90d25145da28c583359beb47b21796b2fe1a23c1511e443e7a64dfdb27d7434c380f0aa4c500e220aa1a9d068514b1ff4d5019e624e7ba1efe82b340a59 -Z f17f52151ebef6c7334fad080c5704d7 1Anton
        // $ ./oclvanitygen -d 2 -P 04af80b90d25145da28c583359beb47b21796b2fe1a23c1511e443e7a64dfdb27d7434c380f0aa4c500e220aa1a9d068514b1ff4d5019e624e7ba1efe82b340a59 -Z f17f52151ebef6c7334fad080c5704d7 1Anton
        //
        // Difficulty: 259627881
        // Pattern: 1Anton
        // Address: 1AntonUpsvweT6ARD8KYrJtkS9Lq9gSgbt
        // PrivkeyPart: 5KeeJmKZv7MBq6hFaYyvPQvJWohaSksgo5bmbjFg7DcpqSBnupS
        //

        //
        // $ ./bitcoin-tool --input-type private-key-wif --input-format base58check --input 5KeeJmKZv7MBq6hFaYyvPQvJWohaSksgo5bmbjFg7DcpqSBnupS --output-type private-key --output-format hex
        //
        // f17f52151ebef6c7334fad080c5704d71ab109046366e2d176132024c220b475
        //

        await taskRegister.solveTask(1, "0xf17f52151ebef6c7334fad080c5704d71ab109046366e2d176132024c220b475", {from: wallet1});

        //
        // $ ./bitcoin-tool --input-type private-key --input-format hex --input c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3 --output-type private-key-wif --output-format base58check --network bitcoin --public-key-compression uncompressed
        //
        // 5KLZzSGDG45CfYC1UYjhwL5yAWb84K8Mpbjy87jw1EwqWpafUDD
        //
        // $ ./bitcoin-tool --input-type private-key --input-format hex --input f17f52151ebef6c7334fad080c5704d71ab109046366e2d176132024c220b475 --output-type private-key-wif --output-format base58check --network bitcoin --public-key-compression uncompressed
        //
        // 5KeeJmKZv7MBq6hFaYyvPQvJWohaSksgo5bmbjFg7DcpqSBnupS
        //
        // $ keyconv -c 5KLZzSGDG45CfYC1UYjhwL5yAWb84K8Mpbjy87jw1EwqWpafUDD 5KeeJmKZv7MBq6hFaYyvPQvJWohaSksgo5bmbjFg7DcpqSBnupS
        // Address: 1AntonUpsvweT6ARD8KYrJtkS9Lq9gSgbt
        // Privkey: 5KEBYHgfFHBB6ovH7KejHNfT5UCyBFYsZwTqWNyHaDj1TKMBuDw
        //
    })

})