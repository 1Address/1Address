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

var VanityLib = artifacts.require("./VanityLib.sol");

contract('VanityLib', async function([_, registratorAccount, customerAccount, customerWallet1, customerWallet2, customerWallet3]) {

    var vanityLib;

    before(async function() {
        vanityLib = await VanityLib.new();
    });

    it("should test lengthOfCommonPrefix", async function() {
        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("456"))).should.be.bignumber.equal(0);
        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("4567"))).should.be.bignumber.equal(0);
        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("1234"), web3.fromAscii("456"))).should.be.bignumber.equal(0);

        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("156"))).should.be.bignumber.equal(1);
        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("1567"))).should.be.bignumber.equal(1);
        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("1234"), web3.fromAscii("156"))).should.be.bignumber.equal(1);

        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("126"))).should.be.bignumber.equal(2);
        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("1267"))).should.be.bignumber.equal(2);
        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("1234"), web3.fromAscii("126"))).should.be.bignumber.equal(2);

        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("123"))).should.be.bignumber.equal(3);
        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii("1237"))).should.be.bignumber.equal(3);
        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("1234"), web3.fromAscii("123"))).should.be.bignumber.equal(3);

        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii("123"), web3.fromAscii(""))).should.be.bignumber.equal(0);
        (await vanityLib.lengthOfCommonPrefix.call(web3.fromAscii(""), web3.fromAscii("1237"))).should.be.bignumber.equal(0);
    })

    it("should test toBase58Checked", async function() {
        (web3.toAscii(await vanityLib.toBase58Checked.call("0x00010966776006953D5567439E5E39F86A0D273BEED61967F6", web3.fromAscii("1")))).should.be.equal("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjv");
    })

    it("should test createBtcAddress", async function() {
        const xPoint = "0x50863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352";
        const yPoint = "0x2CD470243453A299FA9E77237716103ABC11A1DF38855ED6F2EE187E9C582BA6";
        (web3.toAscii(await vanityLib.createBtcAddress.call(xPoint, yPoint))).should.be.equal("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjv");
    })

    it.only("should test complexityForBtcAddressPrefix1", async function() {
        (await vanityLib.complexityForBtcAddressPrefix.call(web3.fromAscii("1AAAAA"), 6)).should.be.bignumber.equal(259627881);
    })

    it("should test complexityForBtcAddressPrefix2", async function() {
        //(await vanityLib.complexityForBtcAddressPrefix.call(web3.fromAscii("1QLbz8"), 6)).should.be.bignumber.equal(837596142);
    })

    it("should test complexityForBtcAddressPrefix3", async function() {
        //(await vanityLib.complexityForBtcAddressPrefix.call(web3.fromAscii("1aaaaa"), 6)).should.be.bignumber.equal(15318045009);
    })

})