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

contract('TaskRegister', async function([_, registratorAccount, customerAccount, customerWallet1, customerWallet2, customerWallet3]) {

    var ec;
    var token;
    var taskRegister;

    before(async function() {
        ec = await EC.new();
        token = await Token.new();
        taskRegister = await TaskRegister.new(ec.address, token.address, 0);
    });

    it("should", async function() {
        await taskRegister.createBitcoinAddressPrefixTask("1Anton", 0, 0);
        await taskRegister.solveTask(1, "0x18e14a7b6a307f426a94f8114701e7c8e774e7f9a47e2c2035db29a206321725");
    })

})