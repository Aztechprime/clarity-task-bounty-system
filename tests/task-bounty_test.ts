import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new task with bounty",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('task-bounty', 'create-task', [
                types.uint(1000),
                types.utf8("Test task description")
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let taskCount = chain.callReadOnlyFn(
            'task-bounty',
            'get-task-count',
            [],
            deployer.address
        );
        
        assertEquals(taskCount.result.expectOk(), types.uint(1));
    },
});

Clarinet.test({
    name: "Cannot complete already completed task",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const worker = accounts.get('wallet_1')!;
        
        // Create and claim task
        chain.mineBlock([
            Tx.contractCall('task-bounty', 'create-task', [
                types.uint(1000),
                types.utf8("Test task description")
            ], deployer.address),
            Tx.contractCall('task-bounty', 'claim-task', [
                types.uint(1)
            ], worker.address)
        ]);
        
        // Complete task first time
        let completeBlock = chain.mineBlock([
            Tx.contractCall('task-bounty', 'complete-task', [
                types.uint(1)
            ], worker.address)
        ]);
        
        completeBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Try completing again
        let secondCompleteBlock = chain.mineBlock([
            Tx.contractCall('task-bounty', 'complete-task', [
                types.uint(1)
            ], worker.address)
        ]);
        
        secondCompleteBlock.receipts[0].result.expectErr().expectUint(108);
    },
});

Clarinet.test({
    name: "Cannot cancel claimed task",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const worker = accounts.get('wallet_1')!;
        
        // Create and claim task
        chain.mineBlock([
            Tx.contractCall('task-bounty', 'create-task', [
                types.uint(1000),
                types.utf8("Test task description")
            ], deployer.address),
            Tx.contractCall('task-bounty', 'claim-task', [
                types.uint(1)
            ], worker.address)
        ]);
        
        // Try canceling claimed task
        let cancelBlock = chain.mineBlock([
            Tx.contractCall('task-bounty', 'cancel-task', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        cancelBlock.receipts[0].result.expectErr().expectUint(102);
    },
});
