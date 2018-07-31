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

contract('EC', async function([_, wallet1, wallet2, wallet3, wallet4, wallet5, wallet6, wallet7, wallet8, wallet9, wallet10]) {

    var ec;
    const gx = "0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
    const gy = "0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8";
    const gx2 = "0xc6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5";
    const gy2 = "0x1ae168fea63dc339a3c58419466ceaeef7f632653266d0e1236431a950cfe52a";
    const gx3 = "0xf9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9";
    const gy3 = "0x388f7b0f632de8140fe337e62a37f3566500a99934c2231b6cb9fd7584b8e672";
    const gx4 = "0xe493dbf1c10d80f3581e4904930b1404cc6c13900ee0758474fa94abe8c4cd13";
    const gy4 = "0x51ed993ea0d455b75642e2098ea51448d967ae33bfbdfe40cfe97bdc47739922";
    const gxA = "0x6a04ab98d9e4774ad806e302dddeb63bea16b5cb5f223ee77478e861bb583eb3";
    const gyA = "0x36b6fbcb60b5b3d4f1551ac45e5ffc4936466e7d98f6c7c0ec736539f74691a6";
    const gxF = "0x9166c289b9f905e55f9e3df9f69d7f356b4a22095f894f4715714aa4b56606af";
    const gyF = "0xf181eb966be4acb5cff9e16b66d809be94e214f06c93fd091099af98499255e7";

    before(async function() {
        ec = await EC.new();
    });

    it("should work for private key 1", async function() {
        const q = await ec.ecmul.call(gx, gy, 1);
        q[0].should.be.bignumber.equal(gx);
        q[1].should.be.bignumber.equal(gy);

        const pk = await ec.publicKey.call(1);
        pk[0].should.be.bignumber.equal(gx);
        pk[1].should.be.bignumber.equal(gy);

        (await ec.ecmulVerify.call(gx, gy, 1, gx, gy)).should.be.true;
        (await ec.publicKeyVerify.call(1, gx, gy)).should.be.true;
    });

    it("should work for private key 2", async function() {
        const q = await ec.ecmul.call(gx, gy, 2);
        q[0].should.be.bignumber.equal(gx2);
        q[1].should.be.bignumber.equal(gy2);

        const pk = await ec.publicKey.call(2);
        pk[0].should.be.bignumber.equal(gx2);
        pk[1].should.be.bignumber.equal(gy2);

        (await ec.ecmulVerify.call(gx, gy, 2, gx2, gy2)).should.be.true;
        (await ec.publicKeyVerify.call(2, gx2, gy2)).should.be.true;
    });

    it("should work for private key 3", async function() {
        const q = await ec.ecmul.call(gx, gy, 3);
        q[0].should.be.bignumber.equal(gx3);
        q[1].should.be.bignumber.equal(gy3);

        const pk = await ec.publicKey.call(3);
        pk[0].should.be.bignumber.equal(gx3);
        pk[1].should.be.bignumber.equal(gy3);

        (await ec.ecmulVerify.call(gx, gy, 3, gx3, gy3)).should.be.true;
        (await ec.publicKeyVerify.call(3, gx3, gy3)).should.be.true;
    });

    it("should work for private key 4", async function() {
        const q = await ec.ecmul.call(gx, gy, 4);
        q[0].should.be.bignumber.equal(gx4);
        q[1].should.be.bignumber.equal(gy4);

        const pk = await ec.publicKey.call(4);
        pk[0].should.be.bignumber.equal(gx4);
        pk[1].should.be.bignumber.equal(gy4);

        (await ec.ecmulVerify.call(gx, gy, 4, gx4, gy4)).should.be.true;
        (await ec.publicKeyVerify.call(4, gx4, gy4)).should.be.true;
    });

    it("should work for private key 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", async function() {
        const q = await ec.ecmul.call(gx, gy, "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
        q[0].should.be.bignumber.equal(gxA);
        q[1].should.be.bignumber.equal(gyA);

        const pk = await ec.publicKey.call("0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
        pk[0].should.be.bignumber.equal(gxA);
        pk[1].should.be.bignumber.equal(gyA);

        (await ec.ecmulVerify.call(gx, gy, "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", gxA, gyA)).should.be.true;
        (await ec.publicKeyVerify.call("0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", gxA, gyA)).should.be.true;
    });

    it("should work for private key 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", async function() {
        const q = await ec.ecmul.call(gx, gy, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
        q[0].should.be.bignumber.equal(gxF);
        q[1].should.be.bignumber.equal(gyF);

        const pk = await ec.publicKey.call("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
        pk[0].should.be.bignumber.equal(gxF);
        pk[1].should.be.bignumber.equal(gyF);

        (await ec.ecmulVerify.call(gx, gy, "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", gxF, gyF)).should.be.true;
        (await ec.publicKeyVerify.call("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", gxF, gyF)).should.be.true;
    });

});