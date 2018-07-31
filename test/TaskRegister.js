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
var TaskRegister = artifacts.require("./TaskRegister.sol");

contract('TaskRegister', async function([_, wallet1, wallet2, wallet3, wallet4, wallet5, wallet6, wallet7, wallet8, wallet9, wallet10]) {

    // PrivKey => PublicKey
    // c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3 => 0x627306090abab3a6e1400e9345bc60c78a8bef57
    // ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f => 0xf17f52151ebef6c7334fad080c5704d77216b732

    var ec;
    var taskRegister;

    before(async function() {
        ec = await EC.new();
        taskRegister = await TaskRegister.new(ec.address, 0);
    });

    it("should work", async function() {
        wallet1.should.be.equal("0xf17f52151ebef6c7334fad080c5704d77216b732");

        //
        // ./bitcoin-tool --input-type private-key --input-format hex --input c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3 --output-type public-key --output-format hex --network bitcoin --public-key-compression uncompressed
        //
        // 04
        // af80b90d25145da28c583359beb47b21796b2fe1a23c1511e443e7a64dfdb27d
        // 7434c380f0aa4c500e220aa1a9d068514b1ff4d5019e624e7ba1efe82b340a59
        //

        const {receipt} = await taskRegister.createBitcoinAddressPrefixTask("1Anton", "0xaf80b90d25145da28c583359beb47b21796b2fe1a23c1511e443e7a64dfdb27d", "0x7434c380f0aa4c500e220aa1a9d068514b1ff4d5019e624e7ba1efe82b340a59", { value: 100 });
        const taskId = web3.toBigNumber(receipt.logs[0].topics[1]);

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

        await taskRegister.solveTask(taskId, "0xf17f52151ebef6c7334fad080c5704d71ab109046366e2d176132024c220b475", "0x310958696132FDB8C276D755D40280C72107ADCC9FC5C854E5384A1E57144320", "0x77976693B8C4FA28B876C8E9DD5A66E3F6FE660538FDF5057CE9587BB7740F3C", {from: wallet1});

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

    it("should work 2", async function() {
        wallet10.should.be.equal("0x0d65ad88abf613060af3c14a3c33c5142eae687b");

        // Private Key: 0D168BA700A19DAF4FE2A6F0EC5B1E335FA84D4C56B15C2B419AC064C3D16EE85
        // Public Key: 
        // 04
        // A3F24A728BEFEEC8C597F74EDE3BCFEC84131C71580DCFD07A1616C9FF536833
        // 76677A9066508541B906945C7EDE71F91D530C76D5706D5728A0D6DCD93455CC
        const {receipt} = await taskRegister.createBitcoinAddressPrefixTask("1Phone", "0xA3F24A728BEFEEC8C597F74EDE3BCFEC84131C71580DCFD07A1616C9FF536833", "0x76677A9066508541B906945C7EDE71F91D530C76D5706D5728A0D6DCD93455CC", { value: 100 });
        const taskId = web3.toBigNumber(receipt.logs[0].topics[1]);

        // Private Key: cede1f04f425831b0b1ef6396779834ff15afa5f176bd9800598bc935bde2477
        await taskRegister.solveTask(taskId, "0x0d65ad88abf613060af3c14a3c33c514a7d48d45c01efde4648d8e7c2ec0f499", "0x4FA73510D9A2CDE09AF0BE48715BD9CAE8EC0D11FDB175A04DB44C60619D9EFD", "0x292BCA57B410C80B9EA44DD205712C4F47136BCC68CADA6B8E34D08B5B901A0B", {from: wallet10});
    })

})