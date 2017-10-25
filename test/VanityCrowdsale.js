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

const Crowdsale = artifacts.require('./VanityCrowdsale.sol');
const Token = artifacts.require('./VanityToken.sol');

contract('VanityCrowdsale', function([_, ownerWallet, wallet, wallet1, wallet2, wallet3, wallet4]) {

    var startTime;
    var endTime;
    var beforeStartTime;
    var beforeEndTime;
    var afterEndTime;

    var crowdsale;
    var token;
    var decimals;

    // https://stackoverflow.com/questions/26107027/
    function makeSuite(name, tests) {
        describe(name, async function () {
            before(async function () {
                await advanceBlock();

                startTime = latestTime() + duration.weeks(1);
                endTime = startTime + duration.weeks(10);
                beforeStartTime = startTime - duration.hours(1);
                beforeEndTime = endTime - duration.hours(1);
                afterEndTime = endTime + duration.seconds(1);

                crowdsale = await Crowdsale.new(startTime, endTime, ownerWallet);
                token = Token.at(await crowdsale.token.call());
                decimals = await token.decimals.call();
            });
            tests();
        });
    }

    makeSuite("before startTime", async function() {

        before(async function() {
            await increaseTimeTo(beforeStartTime);
        })

        it("should fail to register until startTime", async function() {
            await crowdsale.registerParticipant({from: wallet1}).should.be.rejectedWith(EVMThrow);
        })

    })

    makeSuite("since startTime", async function() {

        before(async function() {
            await increaseTimeTo(startTime);
        })

        it("should be able to register", async function() {
            (await crowdsale.registered.call(wallet)).should.be.false;
            await crowdsale.registerParticipant({from: wallet});
            (await crowdsale.registered.call(wallet)).should.be.true;
        })

        it("should not be able to register twice", async function() {
            await crowdsale.registerParticipant({from: wallet1});
            await crowdsale.registerParticipant({from: wallet1}).should.be.rejectedWith(EVMThrow);
        })

        it("should be able to register by payment", async function() {
            (await crowdsale.registered.call(wallet2)).should.be.false;
            web3.eth.sendTransaction({from: wallet2, to: crowdsale.address, value: ether(2), gas: 4700000});
            (await crowdsale.registered.call(wallet2)).should.be.true;
        })

        it("should not be any balance on the contract", async function() {
            (await web3.eth.getBalance(crowdsale.address)).should.be.bignumber.equal(0);
            web3.eth.sendTransaction({from: wallet3, to: crowdsale.address, value: ether(2), gas: 4700000});
            (await web3.eth.getBalance(crowdsale.address)).should.be.bignumber.equal(0);
        })

        it("should return payments to participants", async function() {
            const oldBalance = new BigNumber(await web3.eth.getBalance(wallet4));

            const txid = web3.eth.sendTransaction({from: wallet4, to: crowdsale.address, value: ether(2), gas: 4700000, gasPrice: web3.eth.gasPrice});
            var {cumulativeGasUsed} = web3.eth.getTransactionReceipt(txid);
            cumulativeGasUsed = new BigNumber(cumulativeGasUsed);

            const balance = await web3.eth.getBalance(wallet4);
            balance.should.be.bignumber.equal(oldBalance.sub(cumulativeGasUsed.mul(web3.eth.gasPrice)));
        })

    })

    makeSuite("until endTime", async function() {

        before(async function() {
            await increaseTimeTo(beforeEndTime);
        })

        it("should not be able to finalize by anyone", async function() {
            await crowdsale.finalize({from: wallet1}).should.be.rejectedWith(EVMThrow);
            await crowdsale.finalize().should.be.rejectedWith(EVMThrow);
        })

    })

    makeSuite("after endTime", async function() {

        before(async function() {
            await increaseTimeTo(afterEndTime);
        })

        it("should not be able to register anymore", async function() {
            await crowdsale.registerParticipant({from: wallet1}).should.be.rejectedWith(EVMThrow);
            await crowdsale.registerParticipant({from: wallet2}).should.be.rejectedWith(EVMThrow);
        })

        it("should not be able to finalize not by owner", async function() {
            await crowdsale.finalize({from: wallet1}).should.be.rejectedWith(EVMThrow);
            await crowdsale.finalize({from: wallet2}).should.be.rejectedWith(EVMThrow);
        })

        it("should not be able to distribute by anyone", async function() {
            const participantsCount = await crowdsale.participantsCount.call();
            await crowdsale.distribute(participantsCount, {from: wallet1}).should.be.rejectedWith(EVMThrow);
            await crowdsale.distribute(participantsCount, {from: wallet2}).should.be.rejectedWith(EVMThrow);
            await crowdsale.distribute(participantsCount).should.be.rejectedWith(EVMThrow);
        })

        it("should be able to finalize by owner", async function() {
            (await crowdsale.finalized.call()).should.be.false;
            await crowdsale.finalize();
            (await crowdsale.finalized.call()).should.be.true;
        })

    })

    makeSuite("after finalization", async function() {

        before(async function() {
            await increaseTimeTo(startTime);
            await crowdsale.registerParticipant({from: wallet1});
            await crowdsale.registerParticipant({from: wallet2});
            await crowdsale.registerParticipant({from: wallet3});

            await increaseTimeTo(afterEndTime);
            await crowdsale.finalize();
        })

        it("should not be able to finalize again", async function() {
            await crowdsale.finalize().should.be.rejectedWith(EVMThrow);
        })

        it("should not be able to distribute not by owner", async function() {
            const participantsCount = await crowdsale.participantsCount.call();
            await crowdsale.distribute(participantsCount, {from: wallet1}).should.be.rejectedWith(EVMThrow);
            await crowdsale.distribute(participantsCount, {from: wallet2}).should.be.rejectedWith(EVMThrow);
        })

        it("should not be able to distribute for 0 or too many participants", async function() {
            const participantsCount = await crowdsale.participantsCount.call();
            await crowdsale.distribute(0).should.be.rejectedWith(EVMThrow);
            await crowdsale.distribute(participantsCount + 1).should.be.rejectedWith(EVMThrow);
        })

        it("should be able to distribute by owner", async function() {
            const participants = await crowdsale.participantsCount.call();
            const firstDistributed = 1;

            await crowdsale.distribute(firstDistributed);
            (await crowdsale.distributedCount.call()).should.be.bignumber.equal(firstDistributed);
            (await crowdsale.distributed.call()).should.be.false;

            await crowdsale.distribute(participants - firstDistributed);
            (await crowdsale.distributedCount.call()).should.be.bignumber.equal(participants);
            (await crowdsale.distributed.call()).should.be.true;

            // Check tokens distribution

            const balance1 = new BigNumber(await web3.eth.getBalance(wallet1));
            const balance2 = new BigNumber(await web3.eth.getBalance(wallet2));
            const balance3 = new BigNumber(await web3.eth.getBalance(wallet3));
            const totalBalances = balance1.plus(balance2).plus(balance3);

            (await token.balanceOf.call(wallet1)).toFixed().should.be.equal(balance1.times(1000).toFixed());
            (await token.balanceOf.call(wallet2)).toFixed().should.be.equal(balance2.times(1000).toFixed());
            (await token.balanceOf.call(wallet3)).toFixed().should.be.equal(balance3.times(1000).toFixed());
            (await token.balanceOf.call(ownerWallet)).toFixed().should.be.equal(totalBalances.times(1000).toFixed());
        })

    })

})
