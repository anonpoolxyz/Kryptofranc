#!/usr/bin/env python3
# Copyright (c) 2014-2018 The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.
"""Test the wallet accounts properly when there is a double-spend conflict."""
from decimal import Decimal

from test_framework.test_framework import kryptoFrancTestFramework
from test_framework.util import (
    assert_equal,
    connect_nodes,
    disconnect_nodes,
    find_output,
    sync_blocks,
)

class TxnMallTest(kryptoFrancTestFramework):
    def set_test_params(self):
        self.num_nodes = 4

    def add_options(self, parser):
        parser.add_argument("--mineblock", dest="mine_block", default=False, action="store_true",
                            help="Test double-spend of 1-confirmed transaction")

    def setup_network(self):
        # Start with split network:
        super().setup_network()
        disconnect_nodes(self.nodes[1], 2)
        disconnect_nodes(self.nodes[2], 1)

    def run_test(self):
        # All nodes should start with 1,250 KYF:
        starting_balance = 1250
        for i in range(4):
            assert_equal(self.nodes[i].getbalance(), starting_balance)
            self.nodes[i].getnewaddress("")  # bug workaround, coins generated assigned to first getnewaddress!

        # Assign coins to foo and bar addresses:
        node0_address_foo = self.nodes[0].getnewaddress()
        fund_foo_txid = self.nodes[0].sendtoaddress(node0_address_foo, 1219)
        fund_foo_tx = self.nodes[0].gettransaction(fund_foo_txid)

        node0_address_bar = self.nodes[0].getnewaddress()
        fund_bar_txid = self.nodes[0].sendtoaddress(node0_address_bar, 29)
        fund_bar_tx = self.nodes[0].gettransaction(fund_bar_txid)

        assert_equal(self.nodes[0].getbalance(),
                     starting_balance + fund_foo_tx["fee"] + fund_bar_tx["fee"])

        # Coins are sent to node1_address
        node1_address = self.nodes[1].getnewaddress()

        # First: use raw transaction API to send 1240 KYF to node1_address,
        # but don't broadcast:
        doublespend_fee = Decimal('-.02')
        rawtx_input_0 = {}
        rawtx_input_0["txid"] = fund_foo_txid
        rawtx_input_0["vout"] = find_output(self.nodes[0], fund_foo_txid, 1219)
        rawtx_input_1 = {}
        rawtx_input_1["txid"] = fund_bar_txid
        rawtx_input_1["vout"] = find_output(self.nodes[0], fund_bar_txid, 29)
        inputs = [rawtx_input_0, rawtx_input_1]
        change_address = self.nodes[0].getnewaddress()
        outputs = {}
        outputs[node1_address] = 1240
        outputs[change_address] = 1248 - 1240 + doublespend_fee
        rawtx = self.nodes[0].createrawtransaction(inputs, outputs)
        doublespend = self.nodes[0].signrawtransactionwithwallet(rawtx)
        assert_equal(doublespend["complete"], True)

        # Create two spends using 1 50 KYF coin each
        txid1 = self.nodes[0].sendtoaddress(node1_address, 40)
        txid2 = self.nodes[0].sendtoaddress(node1_address, 20)

        # Have node0 mine a block:
        if (self.options.mine_block):
            self.nodes[0].generate(1)
            sync_blocks(self.nodes[0:2])

        tx1 = self.nodes[0].gettransaction(txid1)
        tx2 = self.nodes[0].gettransaction(txid2)

        # Node0's balance should be starting balance, plus 50KYF for another
        # matured block, minus 40, minus 20, and minus transaction fees:
        expected = starting_balance + fund_foo_tx["fee"] + fund_bar_tx["fee"]
        if self.options.mine_block:
            expected += 50
        expected += tx1["amount"] + tx1["fee"]
        expected += tx2["amount"] + tx2["fee"]
        assert_equal(self.nodes[0].getbalance(), expected)

        if self.options.mine_block:
            assert_equal(tx1["confirmations"], 1)
            assert_equal(tx2["confirmations"], 1)
            # Node1's balance should be both transaction amounts:
            assert_equal(self.nodes[1].getbalance(), starting_balance - tx1["amount"] - tx2["amount"])
        else:
            assert_equal(tx1["confirmations"], 0)
            assert_equal(tx2["confirmations"], 0)

        # Now give doublespend and its parents to miner:
        self.nodes[2].sendrawtransaction(fund_foo_tx["hex"])
        self.nodes[2].sendrawtransaction(fund_bar_tx["hex"])
        doublespend_txid = self.nodes[2].sendrawtransaction(doublespend["hex"])
        # ... mine a block...
        self.nodes[2].generate(1)

        # Reconnect the split network, and sync chain:
        connect_nodes(self.nodes[1], 2)
        self.nodes[2].generate(1)  # Mine another block to make sure we sync
        sync_blocks(self.nodes)
        assert_equal(self.nodes[0].gettransaction(doublespend_txid)["confirmations"], 2)

        # Re-fetch transaction info:
        tx1 = self.nodes[0].gettransaction(txid1)
        tx2 = self.nodes[0].gettransaction(txid2)

        # Both transactions should be conflicted
        assert_equal(tx1["confirmations"], -2)
        assert_equal(tx2["confirmations"], -2)

        # Node0's total balance should be starting balance, plus 100KYF for
        # two more matured blocks, minus 1240 for the double-spend, plus fees (which are
        # negative):
        expected = starting_balance + 100 - 1240 + fund_foo_tx["fee"] + fund_bar_tx["fee"] + doublespend_fee
        assert_equal(self.nodes[0].getbalance(), expected)

        # Node1's balance should be its initial balance (1250 for 25 block rewards) plus the doublespend:
        assert_equal(self.nodes[1].getbalance(), 1250 + 1240)

if __name__ == '__main__':
    TxnMallTest().main()
