import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures minimum bounty requirement",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('task-bounty', 'create-task', [
        types.uint(50), // Below minimum
        types.utf8("Test task description"),
        types.uint(30) // Future block height
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectErr().expectUint(111); // err-invalid-bounty
  },
});

// [Previous test cases remain...]

Clarinet.test({
  name: "Validates rating bounds",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const worker = accounts.get('wallet_1')!;
    
    // Setup: Create and complete task
    let setupBlock = chain.mineBlock([
      Tx.contractCall('task-bounty', 'create-task', [
        types.uint(1000),
        types.utf8("Test task description"),
        types.uint(30)
      ], deployer.address)
    ]);
    
    // Try invalid rating (6)
    let rateBlock = chain.mineBlock([
      Tx.contractCall('task-bounty', 'rate-worker', [
        types.uint(1),
        types.uint(6)
      ], deployer.address)
    ]);
    
    rateBlock.receipts[0].result.expectErr().expectUint(107); // err-invalid-rating
  },
});
