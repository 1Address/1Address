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

    function makeIt(prefix, value) {
        it("should test difficulty for " + prefix, async function() {
            (await vanityLib.complexityForBtcAddressPrefix.call(web3.fromAscii(prefix))).should.be.bignumber.equal(value);
        })
    }

    makeIt('1AAAAA', 259627881);
    makeIt('1QLbz6', 259627881);
    makeIt('1QLbz7', 837596142);
    makeIt('1QLbz8', 15318045009);
    makeIt('1aaaaa', 15318045009);
    makeIt('1zzzzz', 15318045009);
    makeIt('111111', 1099511627776);

    makeIt('1B', 22);
    makeIt('1Bi', 1330);
    makeIt('1Bit', 77178);
    makeIt('1Bitc', 4476342);
    makeIt('1Bitco', 259627881);
    makeIt('1Bitcoi', 15058417127);
    makeIt('1Bitcoin', 873388193410);
    makeIt('1BitcoinEater', "573254251836560363813");
    makeIt('1BitcoinEaterAddress', "1265736312036992302053249573170410");

})